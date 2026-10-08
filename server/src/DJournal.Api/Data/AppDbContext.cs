using Microsoft.AspNetCore.DataProtection.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace DJournal.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options)
    : IdentityDbContext<AppUser, IdentityRole<Guid>, Guid>(options), IDataProtectionKeyContext
{
    public const string SyncVersionSequence = "sync_version_seq";

    public DbSet<Wallet> Wallets => Set<Wallet>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<MoneyTransaction> Transactions => Set<MoneyTransaction>();
    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<JournalEntry> JournalEntries => Set<JournalEntry>();

    /// <summary>Kunci enkripsi token login, disimpan di DB supaya token tetap
    /// valid setelah server restart.</summary>
    public DbSet<DataProtectionKey> DataProtectionKeys => Set<DataProtectionKey>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);

        b.HasSequence<long>(SyncVersionSequence);

        b.Entity<Wallet>(e =>
        {
            ConfigureSync(e);
            e.Property(x => x.Name).HasMaxLength(100);
            e.Property(x => x.Type).HasMaxLength(20);
            e.Property(x => x.Color).HasMaxLength(9);
        });

        b.Entity<Category>(e =>
        {
            ConfigureSync(e);
            e.Property(x => x.Name).HasMaxLength(100);
            e.Property(x => x.Kind).HasMaxLength(20);
            e.Property(x => x.Color).HasMaxLength(9);
            e.Property(x => x.Icon).HasMaxLength(50);
            e.Property(x => x.SystemKey).HasMaxLength(50);
        });

        b.Entity<MoneyTransaction>(e =>
        {
            e.ToTable("transactions");
            ConfigureSync(e);
            e.Property(x => x.Type).HasMaxLength(20);
            e.Property(x => x.Note).HasMaxLength(500);
            e.HasOne<Wallet>().WithMany().HasForeignKey(x => x.WalletId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne<Wallet>().WithMany().HasForeignKey(x => x.ToWalletId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne<Category>().WithMany().HasForeignKey(x => x.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.UserId, x.LocalDate });
        });

        b.Entity<Budget>(e =>
        {
            ConfigureSync(e);
            e.Property(x => x.StartMonth).HasMaxLength(7).IsFixedLength();
            e.HasOne<Category>().WithMany().HasForeignKey(x => x.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => new { x.CategoryId, x.StartMonth }).IsUnique();
        });

        b.Entity<JournalEntry>(e =>
        {
            ConfigureSync(e);
            e.Property(x => x.Title).HasMaxLength(200);
            e.HasIndex(x => new { x.UserId, x.EntryDate });
        });
    }

    private static void ConfigureSync<T>(Microsoft.EntityFrameworkCore.Metadata.Builders.EntityTypeBuilder<T> e)
        where T : SyncEntity
    {
        e.HasKey(x => x.Id);
        // Id dari client, jangan di-generate database.
        e.Property(x => x.Id).ValueGeneratedNever();
        e.HasOne<AppUser>().WithMany().HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        // Index utama untuk pull: "semua baris user ini dengan version > X".
        e.HasIndex(x => new { x.UserId, x.ServerVersion });
    }

    /// <summary>Ambil [count] nomor versi baru dari sequence global.</summary>
    public async Task<Queue<long>> NextVersionsAsync(int count, CancellationToken ct)
    {
        var values = await Database
            .SqlQueryRaw<long>(
                $"SELECT nextval('{SyncVersionSequence}') AS \"Value\" FROM generate_series(1, {{0}})",
                count)
            .ToListAsync(ct);
        return new Queue<long>(values);
    }
}
