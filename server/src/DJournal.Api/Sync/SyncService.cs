using System.Globalization;
using System.Text.RegularExpressions;
using DJournal.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace DJournal.Api.Sync;

/// <summary>Data dari client tidak valid (ditolak dengan 400).</summary>
public class SyncValidationException(string message) : Exception(message);

/// <summary>
/// Sinkronisasi offline-first: push lalu pull, last-write-wins per baris
/// (docs/data-model.md §5).
/// </summary>
public partial class SyncService(AppDbContext db)
{
    private static readonly string[] WalletTypes = ["cash", "bank", "ewallet", "other"];
    private static readonly string[] CategoryKinds = ["expense", "income"];
    private static readonly string[] TxTypes = ["expense", "income", "transfer"];

    [GeneratedRegex(@"^\d{4}-(0[1-9]|1[0-2])$")]
    private static partial Regex MonthRegex();

    public async Task<SyncPushResponse> PushAsync(Guid userId, SyncPushRequest req, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);

        // Satu push per user dalam satu waktu. Dengan begitu urutan
        // server_version untuk user ini = urutan commit, jadi pull tidak
        // pernah melewatkan perubahan.
        await db.Database.ExecuteSqlRawAsync(
            "SELECT pg_advisory_xact_lock(hashtext({0}))", [userId.ToString()], ct);

        var applied = 0;
        var ignored = 0;
        void Count((int a, int i) r) { applied += r.a; ignored += r.i; }

        // Urutan penting: dompet & kategori dulu karena dirujuk transaksi/budget.
        Count(await UpsertAsync(db.Wallets, userId, req.Wallets, d => d.Id, d => d.UpdatedAt,
            (d, e) =>
            {
                Require(WalletTypes.Contains(d.Type), $"wallet {d.Id}: type '{d.Type}' tidak dikenal");
                Require(!string.IsNullOrWhiteSpace(d.Name), $"wallet {d.Id}: nama kosong");
                Copy(d.CreatedAt, d.UpdatedAt, d.DeletedAt, e);
                e.Name = d.Name.Trim();
                e.Type = d.Type;
                e.OpeningBalance = d.OpeningBalance;
                e.Color = d.Color;
                e.SortOrder = d.SortOrder;
                e.IsArchived = d.IsArchived;
            }, ct));

        Count(await UpsertAsync(db.Categories, userId, req.Categories, d => d.Id, d => d.UpdatedAt,
            (d, e) =>
            {
                Require(CategoryKinds.Contains(d.Kind), $"category {d.Id}: kind '{d.Kind}' tidak dikenal");
                Require(!string.IsNullOrWhiteSpace(d.Name), $"category {d.Id}: nama kosong");
                Copy(d.CreatedAt, d.UpdatedAt, d.DeletedAt, e);
                e.Name = d.Name.Trim();
                e.Kind = d.Kind;
                e.Color = d.Color;
                e.Icon = d.Icon;
                e.SortOrder = d.SortOrder;
                e.SystemKey = d.SystemKey;
                e.IsArchived = d.IsArchived;
            }, ct));

        // Simpan dulu supaya validasi referensi di bawah melihat dompet/kategori baru.
        await db.SaveChangesAsync(ct);

        var txs = req.Transactions ?? [];
        var budgets = req.Budgets ?? [];
        await RequireOwnedAsync(db.Wallets, userId,
            txs.SelectMany(t => new[] { t.WalletId, t.ToWalletId ?? t.WalletId }), "wallet", ct);
        await RequireOwnedAsync(db.Categories, userId,
            txs.Where(t => t.CategoryId != null).Select(t => t.CategoryId!.Value)
                .Concat(budgets.Select(b => b.CategoryId)), "category", ct);

        Count(await UpsertAsync(db.Transactions, userId, txs, d => d.Id, d => d.UpdatedAt,
            (d, e) =>
            {
                Require(TxTypes.Contains(d.Type), $"transaction {d.Id}: type '{d.Type}' tidak dikenal");
                Require(d.Amount > 0, $"transaction {d.Id}: amount harus > 0");
                Require(d.Type == "transfer" ? d.ToWalletId != null : d.CategoryId != null,
                    $"transaction {d.Id}: transfer butuh toWalletId, lainnya butuh categoryId");
                Copy(d.CreatedAt, d.UpdatedAt, d.DeletedAt, e);
                e.Type = d.Type;
                e.Amount = d.Amount;
                e.WalletId = d.WalletId;
                e.ToWalletId = d.Type == "transfer" ? d.ToWalletId : null;
                e.CategoryId = d.Type == "transfer" ? null : d.CategoryId;
                e.Note = d.Note;
                e.OccurredAt = d.OccurredAt.ToUniversalTime();
                e.LocalDate = d.LocalDate;
            }, ct));

        Count(await UpsertAsync(db.Budgets, userId, budgets, d => d.Id, d => d.UpdatedAt,
            (d, e) =>
            {
                Require(MonthRegex().IsMatch(d.StartMonth), $"budget {d.Id}: startMonth harus YYYY-MM");
                Require(d.Amount >= 0, $"budget {d.Id}: amount tidak boleh negatif");
                Copy(d.CreatedAt, d.UpdatedAt, d.DeletedAt, e);
                e.CategoryId = d.CategoryId;
                e.Amount = d.Amount;
                e.StartMonth = d.StartMonth;
            }, ct));

        Count(await UpsertAsync(db.JournalEntries, userId, req.JournalEntries, d => d.Id, d => d.UpdatedAt,
            (d, e) =>
            {
                Require(d.Mood is null or (>= 1 and <= 5), $"journal {d.Id}: mood harus 1–5");
                Copy(d.CreatedAt, d.UpdatedAt, d.DeletedAt, e);
                e.EntryDate = d.EntryDate;
                e.EntryTime = ParseTime(d.EntryTime, d.Id);
                e.Mood = d.Mood;
                e.Title = d.Title;
                e.Body = d.Body;
                e.Tags = d.Tags ?? [];
            }, ct));

        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return new SyncPushResponse(applied, ignored);
    }

    public async Task<SyncPullResponse> PullAsync(Guid userId, long since, CancellationToken ct)
    {
        IQueryable<T> Changed<T>(DbSet<T> set) where T : SyncEntity =>
            set.AsNoTracking()
                .Where(e => e.UserId == userId && e.ServerVersion > since)
                .OrderBy(e => e.ServerVersion);

        var wallets = await Changed(db.Wallets).ToListAsync(ct);
        var categories = await Changed(db.Categories).ToListAsync(ct);
        var txs = await Changed(db.Transactions).ToListAsync(ct);
        var budgets = await Changed(db.Budgets).ToListAsync(ct);
        var entries = await Changed(db.JournalEntries).ToListAsync(ct);

        var cursor = new long[] { since }
            .Concat(wallets.Select(e => e.ServerVersion))
            .Concat(categories.Select(e => e.ServerVersion))
            .Concat(txs.Select(e => e.ServerVersion))
            .Concat(budgets.Select(e => e.ServerVersion))
            .Concat(entries.Select(e => e.ServerVersion))
            .Max();

        return new SyncPullResponse(
            cursor,
            [.. wallets.Select(e => new WalletDto(e.Id, e.CreatedAt, e.UpdatedAt, e.DeletedAt,
                e.Name, e.Type, e.OpeningBalance, e.Color, e.SortOrder, e.IsArchived))],
            [.. categories.Select(e => new CategoryDto(e.Id, e.CreatedAt, e.UpdatedAt, e.DeletedAt,
                e.Name, e.Kind, e.Color, e.Icon, e.SortOrder, e.SystemKey, e.IsArchived))],
            [.. txs.Select(e => new TransactionDto(e.Id, e.CreatedAt, e.UpdatedAt, e.DeletedAt,
                e.Type, e.Amount, e.WalletId, e.ToWalletId, e.CategoryId, e.Note, e.OccurredAt, e.LocalDate))],
            [.. budgets.Select(e => new BudgetDto(e.Id, e.CreatedAt, e.UpdatedAt, e.DeletedAt,
                e.CategoryId, e.Amount, e.StartMonth))],
            [.. entries.Select(e => new JournalEntryDto(e.Id, e.CreatedAt, e.UpdatedAt, e.DeletedAt,
                e.EntryDate, e.EntryTime?.ToString("HH:mm", CultureInfo.InvariantCulture),
                e.Mood, e.Title, e.Body, e.Tags))]);
    }

    /// <summary>
    /// Insert baris baru, update kalau versi client lebih baru (last-write-wins),
    /// abaikan kalau versi server lebih baru. Setiap baris yang berubah
    /// mendapat server_version baru.
    /// </summary>
    private async Task<(int applied, int ignored)> UpsertAsync<TEntity, TDto>(
        DbSet<TEntity> set,
        Guid userId,
        List<TDto>? rows,
        Func<TDto, Guid> idOf,
        Func<TDto, DateTimeOffset> updatedAtOf,
        Action<TDto, TEntity> apply,
        CancellationToken ct)
        where TEntity : SyncEntity, new()
    {
        if (rows is not { Count: > 0 }) return (0, 0);

        var ids = rows.Select(idOf).ToList();
        Require(ids.Distinct().Count() == ids.Count, $"{typeof(TEntity).Name}: id duplikat dalam satu push");

        var existing = await set.Where(e => ids.Contains(e.Id)).ToDictionaryAsync(e => e.Id, ct);
        var versions = await db.NextVersionsAsync(rows.Count, ct);
        int applied = 0, ignored = 0;

        foreach (var row in rows)
        {
            var id = idOf(row);
            if (existing.TryGetValue(id, out var entity))
            {
                // Id milik user lain: jangan bocorkan, tolak saja.
                Require(entity.UserId == userId, $"{typeof(TEntity).Name} {id}: id tidak valid");
                if (updatedAtOf(row) <= entity.UpdatedAt)
                {
                    ignored++;
                    continue;
                }
            }
            else
            {
                entity = new TEntity { Id = id, UserId = userId };
                set.Add(entity);
            }

            apply(row, entity);
            entity.ServerVersion = versions.Dequeue();
            applied++;
        }

        return (applied, ignored);
    }

    private static async Task RequireOwnedAsync<T>(
        DbSet<T> set, Guid userId, IEnumerable<Guid> ids, string what, CancellationToken ct)
        where T : SyncEntity
    {
        var wanted = ids.Distinct().ToList();
        if (wanted.Count == 0) return;
        var found = await set.Where(e => e.UserId == userId && wanted.Contains(e.Id))
            .Select(e => e.Id).ToListAsync(ct);
        var missing = wanted.Except(found).FirstOrDefault();
        Require(missing == Guid.Empty, $"{what} {missing} tidak ditemukan; push {what} lebih dulu");
    }

    private static void Copy(DateTimeOffset created, DateTimeOffset updated, DateTimeOffset? deleted, SyncEntity e)
    {
        e.CreatedAt = created.ToUniversalTime();
        e.UpdatedAt = updated.ToUniversalTime();
        e.DeletedAt = deleted?.ToUniversalTime();
    }

    private static TimeOnly? ParseTime(string? hhmm, Guid id)
    {
        if (hhmm is null) return null;
        Require(TimeOnly.TryParseExact(hhmm, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var t),
            $"journal {id}: entryTime harus HH:mm");
        return t;
    }

    private static void Require(bool condition, string message)
    {
        if (!condition) throw new SyncValidationException(message);
    }
}
