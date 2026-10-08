-- djournal: skema dan fungsi sinkronisasi untuk Supabase.
-- Acuan: docs/data-model.md. Logika sama dengan server .NET lama
-- (server/src/DJournal.Api/Sync/SyncService.cs), dipindah ke Postgres.
--
-- Cara pakai: tempel seluruh file ini di Supabase Dashboard → SQL Editor → Run.

-- Nomor urut perubahan global. Pull incremental memakai ini, bukan
-- updated_at, karena jam HP bisa salah.
create sequence if not exists public.sync_version_seq;

-- ------------------------------------------------------------------ tabel

create table public.wallets (
  id              uuid primary key,
  user_id         uuid not null references auth.users (id) on delete cascade,
  created_at      timestamptz not null,
  updated_at      timestamptz not null,
  deleted_at      timestamptz,
  server_version  bigint not null,
  name            text not null check (char_length(name) between 1 and 100),
  type            text not null check (type in ('cash', 'bank', 'ewallet', 'other')),
  opening_balance bigint not null default 0,
  color           text,
  sort_order      integer not null default 0,
  is_archived     boolean not null default false
);

create table public.categories (
  id             uuid primary key,
  user_id        uuid not null references auth.users (id) on delete cascade,
  created_at     timestamptz not null,
  updated_at     timestamptz not null,
  deleted_at     timestamptz,
  server_version bigint not null,
  name           text not null check (char_length(name) between 1 and 100),
  kind           text not null check (kind in ('expense', 'income')),
  color          text not null,
  icon           text,
  sort_order     integer not null default 0,
  system_key     text,
  is_archived    boolean not null default false
);

create table public.transactions (
  id             uuid primary key,
  user_id        uuid not null references auth.users (id) on delete cascade,
  created_at     timestamptz not null,
  updated_at     timestamptz not null,
  deleted_at     timestamptz,
  server_version bigint not null,
  type           text not null check (type in ('expense', 'income', 'transfer')),
  amount         bigint not null check (amount > 0),
  wallet_id      uuid not null references public.wallets (id),
  to_wallet_id   uuid references public.wallets (id),
  category_id    uuid references public.categories (id),
  note           text check (char_length(note) <= 500),
  occurred_at    timestamptz not null,
  local_date     date not null,
  -- Transfer butuh dompet tujuan; pemasukan/pengeluaran butuh kategori.
  check (
    (type = 'transfer' and to_wallet_id is not null and category_id is null)
    or (type <> 'transfer' and category_id is not null and to_wallet_id is null)
  )
);

create table public.budgets (
  id             uuid primary key,
  user_id        uuid not null references auth.users (id) on delete cascade,
  created_at     timestamptz not null,
  updated_at     timestamptz not null,
  deleted_at     timestamptz,
  server_version bigint not null,
  category_id    uuid not null references public.categories (id),
  amount         bigint not null check (amount >= 0),
  start_month    char(7) not null check (start_month ~ '^\d{4}-(0[1-9]|1[0-2])$')
);

create table public.journal_entries (
  id             uuid primary key,
  user_id        uuid not null references auth.users (id) on delete cascade,
  created_at     timestamptz not null,
  updated_at     timestamptz not null,
  deleted_at     timestamptz,
  server_version bigint not null,
  entry_date     date not null,
  entry_time     time,
  mood           integer check (mood between 1 and 5),
  title          text check (char_length(title) <= 200),
  body           text,
  tags           text[] not null default '{}'
);

-- Index utama untuk pull: "baris milik user ini dengan versi > X".
create index wallets_user_version_idx on public.wallets (user_id, server_version);
create index categories_user_version_idx on public.categories (user_id, server_version);
create index transactions_user_version_idx on public.transactions (user_id, server_version);
create index budgets_user_version_idx on public.budgets (user_id, server_version);
create index journal_entries_user_version_idx on public.journal_entries (user_id, server_version);
create index transactions_user_date_idx on public.transactions (user_id, local_date);
create index journal_entries_user_date_idx on public.journal_entries (user_id, entry_date);
create index transactions_wallet_idx on public.transactions (wallet_id);
create index transactions_to_wallet_idx on public.transactions (to_wallet_id);
create index transactions_category_idx on public.transactions (category_id);
-- Satu budget aktif per (kategori, bulan). Baris terhapus boleh menumpuk.
create unique index budgets_category_month_idx
  on public.budgets (category_id, start_month) where deleted_at is null;

-- ---------------------------------------------------------- keamanan (RLS)
-- User hanya bisa MEMBACA barisnya sendiri. Menulis hanya lewat
-- sync_push di bawah (tidak ada policy insert/update/delete).

alter table public.wallets enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.journal_entries enable row level security;

create policy "baca milik sendiri" on public.wallets
  for select using (user_id = (select auth.uid()));
create policy "baca milik sendiri" on public.categories
  for select using (user_id = (select auth.uid()));
create policy "baca milik sendiri" on public.transactions
  for select using (user_id = (select auth.uid()));
create policy "baca milik sendiri" on public.budgets
  for select using (user_id = (select auth.uid()));
create policy "baca milik sendiri" on public.journal_entries
  for select using (user_id = (select auth.uid()));

-- ------------------------------------------------------------- sync_push
-- Terima semua baris yang berubah di HP. Per baris: insert kalau baru,
-- update kalau updatedAt dari HP lebih baru (last-write-wins), abaikan
-- kalau versi server lebih baru. Satu panggilan = satu transaksi: kalau
-- ada baris tidak valid, semuanya dibatalkan.
--
-- Bentuk payload sama dengan DTO server .NET lama (camelCase):
-- { "wallets": [...], "categories": [...], "transactions": [...],
--   "budgets": [...], "journalEntries": [...] }

create or replace function public.sync_push(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid          uuid := auth.uid();
  r            jsonb;
  rid          uuid;
  incoming     timestamptz;
  owner_id     uuid;
  current_upd  timestamptz;
  other_id     uuid;
  other_upd    timestamptz;
  applied      integer := 0;
  ignored      integer := 0;
begin
  if uid is null then
    raise exception 'Belum login' using errcode = '42501';
  end if;

  -- Satu push per user dalam satu waktu, supaya urutan server_version
  -- milik user ini sama dengan urutan commit (pull tidak melewatkan data).
  perform pg_advisory_xact_lock(hashtext(uid::text));

  -- Urutan penting: dompet & kategori dulu karena dirujuk transaksi/budget.

  -- wallets ---------------------------------------------------------------
  for r in select * from jsonb_array_elements(coalesce(payload -> 'wallets', '[]'::jsonb)) loop
    rid := (r ->> 'id')::uuid;
    incoming := (r ->> 'updatedAt')::timestamptz;
    select w.user_id, w.updated_at into owner_id, current_upd
      from public.wallets w where w.id = rid;
    if found and owner_id <> uid then
      raise exception 'wallet %: id tidak valid', rid using errcode = '22023';
    end if;
    if found and incoming <= current_upd then
      ignored := ignored + 1;
      continue;
    end if;

    insert into public.wallets as t (
      id, user_id, created_at, updated_at, deleted_at, server_version,
      name, type, opening_balance, color, sort_order, is_archived)
    values (
      rid, uid, (r ->> 'createdAt')::timestamptz, incoming,
      (r ->> 'deletedAt')::timestamptz, nextval('public.sync_version_seq'),
      btrim(r ->> 'name'), r ->> 'type', (r ->> 'openingBalance')::bigint,
      r ->> 'color', (r ->> 'sortOrder')::integer, (r ->> 'isArchived')::boolean)
    on conflict (id) do update set
      created_at = excluded.created_at, updated_at = excluded.updated_at,
      deleted_at = excluded.deleted_at, server_version = excluded.server_version,
      name = excluded.name, type = excluded.type,
      opening_balance = excluded.opening_balance, color = excluded.color,
      sort_order = excluded.sort_order, is_archived = excluded.is_archived;
    applied := applied + 1;
  end loop;

  -- categories ------------------------------------------------------------
  for r in select * from jsonb_array_elements(coalesce(payload -> 'categories', '[]'::jsonb)) loop
    rid := (r ->> 'id')::uuid;
    incoming := (r ->> 'updatedAt')::timestamptz;
    select c.user_id, c.updated_at into owner_id, current_upd
      from public.categories c where c.id = rid;
    if found and owner_id <> uid then
      raise exception 'category %: id tidak valid', rid using errcode = '22023';
    end if;
    if found and incoming <= current_upd then
      ignored := ignored + 1;
      continue;
    end if;

    insert into public.categories as t (
      id, user_id, created_at, updated_at, deleted_at, server_version,
      name, kind, color, icon, sort_order, system_key, is_archived)
    values (
      rid, uid, (r ->> 'createdAt')::timestamptz, incoming,
      (r ->> 'deletedAt')::timestamptz, nextval('public.sync_version_seq'),
      btrim(r ->> 'name'), r ->> 'kind', r ->> 'color', r ->> 'icon',
      (r ->> 'sortOrder')::integer, r ->> 'systemKey', (r ->> 'isArchived')::boolean)
    on conflict (id) do update set
      created_at = excluded.created_at, updated_at = excluded.updated_at,
      deleted_at = excluded.deleted_at, server_version = excluded.server_version,
      name = excluded.name, kind = excluded.kind, color = excluded.color,
      icon = excluded.icon, sort_order = excluded.sort_order,
      system_key = excluded.system_key, is_archived = excluded.is_archived;
    applied := applied + 1;
  end loop;

  -- transactions ----------------------------------------------------------
  for r in select * from jsonb_array_elements(coalesce(payload -> 'transactions', '[]'::jsonb)) loop
    rid := (r ->> 'id')::uuid;
    incoming := (r ->> 'updatedAt')::timestamptz;

    -- Dompet/kategori yang dirujuk harus milik user ini juga.
    if not exists (select 1 from public.wallets w
                   where w.id = (r ->> 'walletId')::uuid and w.user_id = uid)
       or (r ->> 'toWalletId' is not null and not exists (
             select 1 from public.wallets w
             where w.id = (r ->> 'toWalletId')::uuid and w.user_id = uid)) then
      raise exception 'transaction %: dompet tidak ditemukan; push dompet lebih dulu', rid
        using errcode = '22023';
    end if;
    if r ->> 'categoryId' is not null and not exists (
         select 1 from public.categories c
         where c.id = (r ->> 'categoryId')::uuid and c.user_id = uid) then
      raise exception 'transaction %: kategori tidak ditemukan; push kategori lebih dulu', rid
        using errcode = '22023';
    end if;

    select x.user_id, x.updated_at into owner_id, current_upd
      from public.transactions x where x.id = rid;
    if found and owner_id <> uid then
      raise exception 'transaction %: id tidak valid', rid using errcode = '22023';
    end if;
    if found and incoming <= current_upd then
      ignored := ignored + 1;
      continue;
    end if;

    insert into public.transactions as t (
      id, user_id, created_at, updated_at, deleted_at, server_version,
      type, amount, wallet_id, to_wallet_id, category_id, note,
      occurred_at, local_date)
    values (
      rid, uid, (r ->> 'createdAt')::timestamptz, incoming,
      (r ->> 'deletedAt')::timestamptz, nextval('public.sync_version_seq'),
      r ->> 'type', (r ->> 'amount')::bigint, (r ->> 'walletId')::uuid,
      (r ->> 'toWalletId')::uuid, (r ->> 'categoryId')::uuid, r ->> 'note',
      (r ->> 'occurredAt')::timestamptz, (r ->> 'localDate')::date)
    on conflict (id) do update set
      created_at = excluded.created_at, updated_at = excluded.updated_at,
      deleted_at = excluded.deleted_at, server_version = excluded.server_version,
      type = excluded.type, amount = excluded.amount,
      wallet_id = excluded.wallet_id, to_wallet_id = excluded.to_wallet_id,
      category_id = excluded.category_id, note = excluded.note,
      occurred_at = excluded.occurred_at, local_date = excluded.local_date;
    applied := applied + 1;
  end loop;

  -- budgets ---------------------------------------------------------------
  for r in select * from jsonb_array_elements(coalesce(payload -> 'budgets', '[]'::jsonb)) loop
    rid := (r ->> 'id')::uuid;
    incoming := (r ->> 'updatedAt')::timestamptz;

    if not exists (select 1 from public.categories c
                   where c.id = (r ->> 'categoryId')::uuid and c.user_id = uid) then
      raise exception 'budget %: kategori tidak ditemukan; push kategori lebih dulu', rid
        using errcode = '22023';
    end if;

    select b.user_id, b.updated_at into owner_id, current_upd
      from public.budgets b where b.id = rid;
    if found and owner_id <> uid then
      raise exception 'budget %: id tidak valid', rid using errcode = '22023';
    end if;
    if found and incoming <= current_upd then
      ignored := ignored + 1;
      continue;
    end if;

    -- Dua device offline bisa membuat budget berbeda untuk kategori+bulan
    -- yang sama. Yang lebih baru menang; yang kalah ditandai terhapus
    -- supaya device lain ikut membuangnya saat pull.
    if r ->> 'deletedAt' is null then
      select b.id, b.updated_at into other_id, other_upd
        from public.budgets b
        where b.category_id = (r ->> 'categoryId')::uuid
          and b.start_month = r ->> 'startMonth'
          and b.deleted_at is null
          and b.id <> rid;
      if found then
        if incoming > other_upd then
          update public.budgets
            set deleted_at = now(), updated_at = now(),
                server_version = nextval('public.sync_version_seq')
            where id = other_id;
        else
          r := r || jsonb_build_object('deletedAt', now(), 'updatedAt', now());
          incoming := now();
        end if;
      end if;
    end if;

    insert into public.budgets as t (
      id, user_id, created_at, updated_at, deleted_at, server_version,
      category_id, amount, start_month)
    values (
      rid, uid, (r ->> 'createdAt')::timestamptz, incoming,
      (r ->> 'deletedAt')::timestamptz, nextval('public.sync_version_seq'),
      (r ->> 'categoryId')::uuid, (r ->> 'amount')::bigint, r ->> 'startMonth')
    on conflict (id) do update set
      created_at = excluded.created_at, updated_at = excluded.updated_at,
      deleted_at = excluded.deleted_at, server_version = excluded.server_version,
      category_id = excluded.category_id, amount = excluded.amount,
      start_month = excluded.start_month;
    applied := applied + 1;
  end loop;

  -- journal_entries -------------------------------------------------------
  for r in select * from jsonb_array_elements(coalesce(payload -> 'journalEntries', '[]'::jsonb)) loop
    rid := (r ->> 'id')::uuid;
    incoming := (r ->> 'updatedAt')::timestamptz;
    select j.user_id, j.updated_at into owner_id, current_upd
      from public.journal_entries j where j.id = rid;
    if found and owner_id <> uid then
      raise exception 'journal %: id tidak valid', rid using errcode = '22023';
    end if;
    if found and incoming <= current_upd then
      ignored := ignored + 1;
      continue;
    end if;

    insert into public.journal_entries as t (
      id, user_id, created_at, updated_at, deleted_at, server_version,
      entry_date, entry_time, mood, title, body, tags)
    values (
      rid, uid, (r ->> 'createdAt')::timestamptz, incoming,
      (r ->> 'deletedAt')::timestamptz, nextval('public.sync_version_seq'),
      (r ->> 'entryDate')::date, (r ->> 'entryTime')::time,
      (r ->> 'mood')::integer, r ->> 'title', r ->> 'body',
      case when jsonb_typeof(r -> 'tags') = 'array'
           then array(select jsonb_array_elements_text(r -> 'tags'))
           else '{}'::text[] end)
    on conflict (id) do update set
      created_at = excluded.created_at, updated_at = excluded.updated_at,
      deleted_at = excluded.deleted_at, server_version = excluded.server_version,
      entry_date = excluded.entry_date, entry_time = excluded.entry_time,
      mood = excluded.mood, title = excluded.title, body = excluded.body,
      tags = excluded.tags;
    applied := applied + 1;
  end loop;

  return jsonb_build_object('applied', applied, 'ignored', ignored);
end;
$$;

-- ------------------------------------------------------------- sync_pull
-- Semua baris milik user dengan server_version > since, termasuk yang
-- sudah dihapus (deletedAt terisi). Simpan "cursor" dari hasilnya untuk
-- pull berikutnya.

create or replace function public.sync_pull(since bigint default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Belum login' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'cursor', greatest(
      since,
      coalesce((select max(server_version) from public.wallets where user_id = uid), 0),
      coalesce((select max(server_version) from public.categories where user_id = uid), 0),
      coalesce((select max(server_version) from public.transactions where user_id = uid), 0),
      coalesce((select max(server_version) from public.budgets where user_id = uid), 0),
      coalesce((select max(server_version) from public.journal_entries where user_id = uid), 0)),

    'wallets', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', w.id, 'createdAt', w.created_at, 'updatedAt', w.updated_at,
        'deletedAt', w.deleted_at, 'name', w.name, 'type', w.type,
        'openingBalance', w.opening_balance, 'color', w.color,
        'sortOrder', w.sort_order, 'isArchived', w.is_archived)
        order by w.server_version)
      from public.wallets w
      where w.user_id = uid and w.server_version > since), '[]'::jsonb),

    'categories', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', c.id, 'createdAt', c.created_at, 'updatedAt', c.updated_at,
        'deletedAt', c.deleted_at, 'name', c.name, 'kind', c.kind,
        'color', c.color, 'icon', c.icon, 'sortOrder', c.sort_order,
        'systemKey', c.system_key, 'isArchived', c.is_archived)
        order by c.server_version)
      from public.categories c
      where c.user_id = uid and c.server_version > since), '[]'::jsonb),

    'transactions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', x.id, 'createdAt', x.created_at, 'updatedAt', x.updated_at,
        'deletedAt', x.deleted_at, 'type', x.type, 'amount', x.amount,
        'walletId', x.wallet_id, 'toWalletId', x.to_wallet_id,
        'categoryId', x.category_id, 'note', x.note,
        'occurredAt', x.occurred_at, 'localDate', x.local_date)
        order by x.server_version)
      from public.transactions x
      where x.user_id = uid and x.server_version > since), '[]'::jsonb),

    'budgets', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', b.id, 'createdAt', b.created_at, 'updatedAt', b.updated_at,
        'deletedAt', b.deleted_at, 'categoryId', b.category_id,
        'amount', b.amount, 'startMonth', b.start_month)
        order by b.server_version)
      from public.budgets b
      where b.user_id = uid and b.server_version > since), '[]'::jsonb),

    'journalEntries', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', j.id, 'createdAt', j.created_at, 'updatedAt', j.updated_at,
        'deletedAt', j.deleted_at, 'entryDate', j.entry_date,
        'entryTime', to_char(j.entry_time, 'HH24:MI'), 'mood', j.mood,
        'title', j.title, 'body', j.body, 'tags', to_jsonb(j.tags))
        order by j.server_version)
      from public.journal_entries j
      where j.user_id = uid and j.server_version > since), '[]'::jsonb)
  );
end;
$$;

-- Hanya user yang sudah login yang boleh memanggil fungsi sync.
revoke execute on function public.sync_push(jsonb) from public, anon;
revoke execute on function public.sync_pull(bigint) from public, anon;
grant execute on function public.sync_push(jsonb) to authenticated;
grant execute on function public.sync_pull(bigint) to authenticated;
