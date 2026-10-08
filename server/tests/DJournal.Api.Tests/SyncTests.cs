using System.Net;
using System.Net.Http.Json;
using DJournal.Api.Sync;

namespace DJournal.Api.Tests;

[Collection(ApiCollection.Name)]
public class SyncTests(ApiFactory factory)
{
    private static readonly DateTimeOffset T0 = new(2026, 10, 8, 1, 0, 0, TimeSpan.Zero);

    private static WalletDto Wallet(Guid id, string name = "Tunai", DateTimeOffset? updated = null) =>
        new(id, T0, updated ?? T0, null, name, "cash", 100_000, null, 0, false);

    private static CategoryDto Food(Guid id) =>
        new(id, T0, T0, null, "Makan", "expense", "#9A3412", null, 0, "food", false);

    private static TransactionDto Expense(Guid id, Guid wallet, Guid category, long amount = 25_000) =>
        new(id, T0, T0, null, "expense", amount, wallet, null, category, "Kopi susu",
            T0, new DateOnly(2026, 10, 8));

    private static SyncPushRequest Push(
        WalletDto[]? w = null, CategoryDto[]? c = null, TransactionDto[]? t = null,
        BudgetDto[]? b = null, JournalEntryDto[]? j = null) =>
        new(w?.ToList(), c?.ToList(), t?.ToList(), b?.ToList(), j?.ToList());

    private static async Task<SyncPullResponse> PullAsync(HttpClient client, long since = 0) =>
        (await client.GetFromJsonAsync<SyncPullResponse>($"/api/sync/pull?since={since}"))!;

    [Fact]
    public async Task Health_tanpa_login()
    {
        var res = await factory.CreateClient().GetAsync("/api/health");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task Sync_butuh_login()
    {
        var res = await factory.CreateClient().GetAsync("/api/sync/pull");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task Me_mengembalikan_email_user()
    {
        var client = await factory.CreateUserClientAsync("budi@example.com");
        var me = await client.GetFromJsonAsync<Dictionary<string, object?>>("/api/me");
        Assert.Equal("budi@example.com", me!["email"]?.ToString());
    }

    [Fact]
    public async Task Push_lalu_pull_mengembalikan_semua_data_dan_cursor()
    {
        var client = await factory.CreateUserClientAsync();
        var (w, c, t, e) = (Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid());

        var res = await client.PostAsJsonAsync("/api/sync/push", Push(
            [Wallet(w)], [Food(c)], [Expense(t, w, c)],
            [new BudgetDto(Guid.NewGuid(), T0, T0, null, c, 1_000_000, "2026-10")],
            [new JournalEntryDto(e, T0, T0, null, new DateOnly(2026, 10, 8), "07:30", 4,
                "Sarapan", "Nasi uduk", ["pagi"])]));
        res.EnsureSuccessStatusCode();
        var push = await res.Content.ReadFromJsonAsync<SyncPushResponse>();
        Assert.Equal(5, push!.Applied);

        var pull = await PullAsync(client);
        Assert.True(pull.Cursor > 0);
        Assert.Single(pull.Wallets);
        Assert.Equal(25_000, pull.Transactions.Single().Amount);
        Assert.Equal("2026-10", pull.Budgets.Single().StartMonth);
        var entry = pull.JournalEntries.Single();
        Assert.Equal("07:30", entry.EntryTime);
        Assert.Equal(["pagi"], entry.Tags);

        // Pull berikutnya dengan cursor terakhir: tidak ada yang baru.
        var again = await PullAsync(client, pull.Cursor);
        Assert.Equal(pull.Cursor, again.Cursor);
        Assert.Empty(again.Wallets);
        Assert.Empty(again.Transactions);
    }

    [Fact]
    public async Task Last_write_wins_berdasarkan_updatedAt()
    {
        var client = await factory.CreateUserClientAsync();
        var w = Guid.NewGuid();
        await client.PostAsJsonAsync("/api/sync/push", Push([Wallet(w, "BCA", T0.AddMinutes(10))]));
        var cursor = (await PullAsync(client)).Cursor;

        // Versi lebih lama dari device lain: kalah, diabaikan.
        var older = await (await client.PostAsJsonAsync("/api/sync/push",
            Push([Wallet(w, "BCA lama", T0.AddMinutes(5))]))).Content.ReadFromJsonAsync<SyncPushResponse>();
        Assert.Equal((0, 1), (older!.Applied, older.Ignored));
        Assert.Empty((await PullAsync(client, cursor)).Wallets);

        // Versi lebih baru: menang dan muncul di pull berikutnya.
        var newer = await (await client.PostAsJsonAsync("/api/sync/push",
            Push([Wallet(w, "BCA baru", T0.AddMinutes(20))]))).Content.ReadFromJsonAsync<SyncPushResponse>();
        Assert.Equal(1, newer!.Applied);
        Assert.Equal("BCA baru", (await PullAsync(client, cursor)).Wallets.Single().Name);
    }

    [Fact]
    public async Task Soft_delete_ikut_tersinkron()
    {
        var client = await factory.CreateUserClientAsync();
        var (w, c, t) = (Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid());
        await client.PostAsJsonAsync("/api/sync/push", Push([Wallet(w)], [Food(c)], [Expense(t, w, c)]));
        var cursor = (await PullAsync(client)).Cursor;

        var deleted = Expense(t, w, c) with { UpdatedAt = T0.AddHours(1), DeletedAt = T0.AddHours(1) };
        (await client.PostAsJsonAsync("/api/sync/push", Push(t: [deleted]))).EnsureSuccessStatusCode();

        var tx = (await PullAsync(client, cursor)).Transactions.Single();
        Assert.NotNull(tx.DeletedAt);
    }

    [Fact]
    public async Task Data_antar_user_terpisah()
    {
        var alice = await factory.CreateUserClientAsync();
        var bob = await factory.CreateUserClientAsync();
        var w = Guid.NewGuid();
        await alice.PostAsJsonAsync("/api/sync/push", Push([Wallet(w)]));

        Assert.Empty((await PullAsync(bob)).Wallets);

        // Bob tidak bisa menimpa dompet milik Alice walau tahu id-nya.
        var res = await bob.PostAsJsonAsync("/api/sync/push", Push([Wallet(w, "Punya Bob", T0.AddDays(1))]));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
        Assert.Equal("Tunai", (await PullAsync(alice)).Wallets.Single().Name);
    }

    [Fact]
    public async Task Transaksi_dengan_dompet_tidak_dikenal_ditolak()
    {
        var client = await factory.CreateUserClientAsync();
        var c = Guid.NewGuid();
        var res = await client.PostAsJsonAsync("/api/sync/push",
            Push(c: [Food(c)], t: [Expense(Guid.NewGuid(), Guid.NewGuid(), c)]));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);

        // Seluruh push dibatalkan (satu transaksi database).
        Assert.Empty((await PullAsync(client)).Categories);
    }
}
