using Microsoft.AspNetCore.Identity;

namespace DJournal.Api.Data;

public class AppUser : IdentityUser<Guid>
{
    public string? DisplayName { get; set; }

    /// <summary>"id" atau "en".</summary>
    public string Locale { get; set; } = "id";
}

/// <summary>
/// Kolom standar semua tabel yang disinkronkan (docs/data-model.md §3).
/// Id dibuat oleh client (UUID), bukan oleh database.
/// </summary>
public abstract class SyncEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>Dipakai untuk resolusi konflik (last-write-wins).</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }

    /// <summary>
    /// Nomor urut perubahan global dari sequence Postgres. Pull incremental
    /// memakai ini, bukan UpdatedAt, karena jam HP bisa salah.
    /// </summary>
    public long ServerVersion { get; set; }
}

public class Wallet : SyncEntity
{
    public string Name { get; set; } = "";

    /// <summary>cash | bank | ewallet | other</summary>
    public string Type { get; set; } = "cash";
    public long OpeningBalance { get; set; }
    public string? Color { get; set; }
    public int SortOrder { get; set; }
    public bool IsArchived { get; set; }
}

public class Category : SyncEntity
{
    public string Name { get; set; } = "";

    /// <summary>expense | income</summary>
    public string Kind { get; set; } = "expense";
    public string Color { get; set; } = "";
    public string? Icon { get; set; }
    public int SortOrder { get; set; }
    public string? SystemKey { get; set; }
    public bool IsArchived { get; set; }
}

public class MoneyTransaction : SyncEntity
{
    /// <summary>expense | income | transfer</summary>
    public string Type { get; set; } = "expense";

    /// <summary>Selalu positif, dalam Rupiah.</summary>
    public long Amount { get; set; }
    public Guid WalletId { get; set; }
    public Guid? ToWalletId { get; set; }
    public Guid? CategoryId { get; set; }
    public string? Note { get; set; }
    public DateTimeOffset OccurredAt { get; set; }
    public DateOnly LocalDate { get; set; }
}

public class Budget : SyncEntity
{
    public Guid CategoryId { get; set; }
    public long Amount { get; set; }

    /// <summary>YYYY-MM</summary>
    public string StartMonth { get; set; } = "";
}

public class JournalEntry : SyncEntity
{
    public DateOnly EntryDate { get; set; }
    public TimeOnly? EntryTime { get; set; }

    /// <summary>1–5</summary>
    public int? Mood { get; set; }
    public string? Title { get; set; }
    public string? Body { get; set; }
    public List<string> Tags { get; set; } = [];
}
