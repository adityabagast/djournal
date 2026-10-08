-- Uji fungsi sync_push / sync_pull. Dijalankan oleh supabase/tests/run-local.ps1
-- setelah local_harness.sql dan migration. Gagal = exception (psql berhenti).
\set ON_ERROR_STOP on

create or replace function pg_temp.assert_true(ok boolean, msg text) returns void
language plpgsql as $$
begin
  if not coalesce(ok, false) then raise exception 'GAGAL: %', msg; end if;
end $$;

create or replace function pg_temp.login(uid uuid) returns void
language sql as $$ select set_config('request.jwt.claim.sub', coalesce(uid::text, ''), false) $$;

insert into auth.users values
  ('aaaaaaaa-0000-0000-0000-000000000001'),
  ('bbbbbbbb-0000-0000-0000-000000000002');

-- 1. Push lengkap lalu pull ------------------------------------------------
select pg_temp.login('aaaaaaaa-0000-0000-0000-000000000001');
select pg_temp.assert_true(
  public.sync_push($json${
    "wallets": [{"id":"11111111-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"name":" Tunai ","type":"cash","openingBalance":100000,"color":null,"sortOrder":0,"isArchived":false}],
    "categories": [{"id":"22222222-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"name":"Makan","kind":"expense","color":"#9A3412","icon":null,"sortOrder":0,"systemKey":"food","isArchived":false}],
    "transactions": [{"id":"33333333-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"type":"expense","amount":25000,"walletId":"11111111-0000-0000-0000-000000000001","toWalletId":null,"categoryId":"22222222-0000-0000-0000-000000000001","note":"Kopi susu","occurredAt":"2026-10-08T00:45:00Z","localDate":"2026-10-08"}],
    "budgets": [{"id":"44444444-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"categoryId":"22222222-0000-0000-0000-000000000001","amount":1000000,"startMonth":"2026-10"}],
    "journalEntries": [{"id":"55555555-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"entryDate":"2026-10-08","entryTime":"07:30","mood":4,"title":"Sarapan","body":"Nasi uduk","tags":["pagi"]}]
  }$json$::jsonb) = '{"applied":5,"ignored":0}'::jsonb,
  'push pertama menyimpan 5 baris');

do $$
declare p jsonb := public.sync_pull(0);
begin
  perform pg_temp.assert_true((p ->> 'cursor')::bigint > 0, 'cursor > 0');
  perform pg_temp.assert_true(jsonb_array_length(p -> 'wallets') = 1, 'pull 1 dompet');
  perform pg_temp.assert_true(p -> 'wallets' -> 0 ->> 'name' = 'Tunai', 'nama dompet di-trim');
  perform pg_temp.assert_true((p -> 'transactions' -> 0 ->> 'amount')::bigint = 25000, 'nominal transaksi');
  perform pg_temp.assert_true(p -> 'transactions' -> 0 ->> 'localDate' = '2026-10-08', 'localDate');
  perform pg_temp.assert_true(p -> 'budgets' -> 0 ->> 'startMonth' = '2026-10', 'startMonth');
  perform pg_temp.assert_true(p -> 'journalEntries' -> 0 ->> 'entryTime' = '07:30', 'entryTime HH:mm');
  perform pg_temp.assert_true(p -> 'journalEntries' -> 0 -> 'tags' = '["pagi"]'::jsonb, 'tags array');

  -- Pull lagi dengan cursor terakhir: kosong.
  p := public.sync_pull((p ->> 'cursor')::bigint);
  perform pg_temp.assert_true(jsonb_array_length(p -> 'wallets') = 0
                        and jsonb_array_length(p -> 'transactions') = 0, 'pull incremental kosong');
end $$;

-- 2. Last-write-wins -------------------------------------------------------
do $$
declare
  cur bigint := (public.sync_pull(0) ->> 'cursor')::bigint;
  res jsonb;
begin
  res := public.sync_push('{"wallets":[{"id":"11111111-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T00:30:00Z","deletedAt":null,"name":"Lama","type":"cash","openingBalance":0,"color":null,"sortOrder":0,"isArchived":false}]}');
  perform pg_temp.assert_true(res = '{"applied":0,"ignored":1}', 'versi lebih lama diabaikan');
  perform pg_temp.assert_true(jsonb_array_length(public.sync_pull(cur) -> 'wallets') = 0, 'tidak ada perubahan');

  res := public.sync_push('{"wallets":[{"id":"11111111-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T02:00:00Z","deletedAt":null,"name":"Dompet baru","type":"cash","openingBalance":0,"color":null,"sortOrder":0,"isArchived":false}]}');
  perform pg_temp.assert_true(res = '{"applied":1,"ignored":0}', 'versi lebih baru menang');
  perform pg_temp.assert_true(public.sync_pull(cur) -> 'wallets' -> 0 ->> 'name' = 'Dompet baru', 'perubahan ikut pull');
end $$;

-- 3. Soft delete ikut tersinkron -------------------------------------------
do $$
declare cur bigint := (public.sync_pull(0) ->> 'cursor')::bigint;
begin
  perform public.sync_push('{"transactions":[{"id":"33333333-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T03:00:00Z","deletedAt":"2026-10-08T03:00:00Z","type":"expense","amount":25000,"walletId":"11111111-0000-0000-0000-000000000001","toWalletId":null,"categoryId":"22222222-0000-0000-0000-000000000001","note":"Kopi susu","occurredAt":"2026-10-08T00:45:00Z","localDate":"2026-10-08"}]}');
  perform pg_temp.assert_true(public.sync_pull(cur) -> 'transactions' -> 0 ->> 'deletedAt' is not null, 'deletedAt ikut pull');
end $$;

-- 4. Data antar user terpisah ----------------------------------------------
select pg_temp.login('bbbbbbbb-0000-0000-0000-000000000002');
do $$
begin
  perform pg_temp.assert_true(jsonb_array_length(public.sync_pull(0) -> 'wallets') = 0, 'user B tidak melihat data A');
  begin
    perform public.sync_push('{"wallets":[{"id":"11111111-0000-0000-0000-000000000001","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-09T00:00:00Z","deletedAt":null,"name":"Punya B","type":"cash","openingBalance":0,"color":null,"sortOrder":0,"isArchived":false}]}');
    raise exception 'GAGAL: user B bisa menimpa dompet A';
  exception when sqlstate '22023' then null;
  end;
  -- B juga tidak boleh memakai dompet A untuk transaksinya.
  begin
    perform public.sync_push('{"categories":[{"id":"22222222-0000-0000-0000-0000000000b1","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"name":"Makan","kind":"expense","color":"#000000","icon":null,"sortOrder":0,"systemKey":"food","isArchived":false}],"transactions":[{"id":"33333333-0000-0000-0000-0000000000b1","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"type":"expense","amount":1,"walletId":"11111111-0000-0000-0000-000000000001","toWalletId":null,"categoryId":"22222222-0000-0000-0000-0000000000b1","note":null,"occurredAt":"2026-10-08T00:45:00Z","localDate":"2026-10-08"}]}');
    raise exception 'GAGAL: user B bisa memakai dompet A';
  exception when sqlstate '22023' then null;
  end;
  -- Push yang gagal dibatalkan seluruhnya: kategori B tidak tersimpan.
  perform pg_temp.assert_true(jsonb_array_length(public.sync_pull(0) -> 'categories') = 0, 'push gagal dibatalkan total');
end $$;

select pg_temp.login('aaaaaaaa-0000-0000-0000-000000000001');
do $$
begin
  perform pg_temp.assert_true(public.sync_pull(0) -> 'wallets' -> 0 ->> 'name' = 'Dompet baru', 'dompet A tidak berubah');
end $$;

-- 5. Budget bentrok dari dua device ----------------------------------------
do $$
declare p jsonb;
begin
  perform public.sync_push('{"budgets":[{"id":"44444444-0000-0000-0000-000000000002","createdAt":"2026-10-08T05:00:00Z","updatedAt":"2026-10-08T05:00:00Z","deletedAt":null,"categoryId":"22222222-0000-0000-0000-000000000001","amount":1500000,"startMonth":"2026-10"}]}');
  p := public.sync_pull(0);
  perform pg_temp.assert_true(
    (select count(*) from jsonb_array_elements(p -> 'budgets') b where b ->> 'deletedAt' is null) = 1,
    'hanya satu budget aktif per kategori+bulan');
  perform pg_temp.assert_true(
    (select b ->> 'amount' from jsonb_array_elements(p -> 'budgets') b where b ->> 'deletedAt' is null) = '1500000',
    'budget yang lebih baru menang');
end $$;

-- 6. Tanpa login ditolak ---------------------------------------------------
select pg_temp.login(null);
do $$
begin
  begin
    perform public.sync_pull(0);
    raise exception 'GAGAL: pull tanpa login diterima';
  exception when sqlstate '42501' then null;
  end;
end $$;

-- 7. Validasi isi ----------------------------------------------------------
select pg_temp.login('aaaaaaaa-0000-0000-0000-000000000001');
do $$
begin
  begin
    perform public.sync_push('{"journalEntries":[{"id":"55555555-0000-0000-0000-000000000009","createdAt":"2026-10-08T01:00:00Z","updatedAt":"2026-10-08T01:00:00Z","deletedAt":null,"entryDate":"2026-10-08","entryTime":null,"mood":9,"title":null,"body":"x","tags":null}]}');
    raise exception 'GAGAL: mood 9 diterima';
  exception when check_violation then null;
  end;
end $$;

\echo 'SEMUA TES LULUS'
