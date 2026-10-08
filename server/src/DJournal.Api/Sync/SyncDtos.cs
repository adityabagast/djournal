namespace DJournal.Api.Sync;

// Bentuk baris yang dikirim/diterima client. Field sama dengan tabel di
// HP (docs/data-model.md §4), tanpa kolom khusus server/client.

public record WalletDto(
    Guid Id,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? DeletedAt,
    string Name,
    string Type,
    long OpeningBalance,
    string? Color,
    int SortOrder,
    bool IsArchived);

public record CategoryDto(
    Guid Id,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? DeletedAt,
    string Name,
    string Kind,
    string Color,
    string? Icon,
    int SortOrder,
    string? SystemKey,
    bool IsArchived);

public record TransactionDto(
    Guid Id,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? DeletedAt,
    string Type,
    long Amount,
    Guid WalletId,
    Guid? ToWalletId,
    Guid? CategoryId,
    string? Note,
    DateTimeOffset OccurredAt,
    DateOnly LocalDate);

public record BudgetDto(
    Guid Id,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? DeletedAt,
    Guid CategoryId,
    long Amount,
    string StartMonth);

public record JournalEntryDto(
    Guid Id,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? DeletedAt,
    DateOnly EntryDate,
    /// <summary>"HH:mm" atau null.</summary>
    string? EntryTime,
    int? Mood,
    string? Title,
    string? Body,
    List<string>? Tags);

/// <summary>Semua baris yang berubah di HP sejak push terakhir.</summary>
public record SyncPushRequest(
    List<WalletDto>? Wallets,
    List<CategoryDto>? Categories,
    List<TransactionDto>? Transactions,
    List<BudgetDto>? Budgets,
    List<JournalEntryDto>? JournalEntries);

/// <param name="Applied">Baris yang disimpan (baru atau lebih baru dari server).</param>
/// <param name="Ignored">Baris yang kalah karena versi server lebih baru;
/// versi server akan datang lewat pull.</param>
public record SyncPushResponse(int Applied, int Ignored);

/// <param name="Cursor">Simpan di HP, kirim sebagai <c>since</c> pada pull berikutnya.</param>
public record SyncPullResponse(
    long Cursor,
    List<WalletDto> Wallets,
    List<CategoryDto> Categories,
    List<TransactionDto> Transactions,
    List<BudgetDto> Budgets,
    List<JournalEntryDto> JournalEntries);
