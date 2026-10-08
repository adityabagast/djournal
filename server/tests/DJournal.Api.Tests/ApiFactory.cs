using System.Net.Http.Headers;
using System.Net.Http.Json;
using DJournal.Api.Data;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;

namespace DJournal.Api.Tests;

/// <summary>
/// Menjalankan API di memori dengan database PostgreSQL sementara
/// (djournal_test_xxx) yang dibuat di awal dan dihapus di akhir.
/// Connection string diambil dari user-secrets project API.
/// </summary>
public class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly string _connectionString;

    public ApiFactory()
    {
        var config = new ConfigurationBuilder()
            .AddUserSecrets<ApiFactory>(optional: true)
            .AddUserSecrets(typeof(AppDbContext).Assembly, optional: true)
            .AddEnvironmentVariables()
            .Build();
        var baseCs = config.GetConnectionString("Default")
            ?? throw new InvalidOperationException(
                "ConnectionStrings:Default belum diatur di user-secrets DJournal.Api.");

        _connectionString = new NpgsqlConnectionStringBuilder(baseCs)
        {
            Database = $"djournal_test_{Guid.NewGuid():N}"[..30],
        }.ConnectionString;
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("ConnectionStrings:Default", _connectionString);
    }

    public async Task InitializeAsync()
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync();
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        using (var scope = Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            NpgsqlConnection.ClearAllPools();
            await db.Database.EnsureDeletedAsync();
        }
        await base.DisposeAsync();
    }

    /// <summary>Daftar user baru, login, dan kembalikan client ber-token.</summary>
    public async Task<HttpClient> CreateUserClientAsync(string? email = null)
    {
        email ??= $"user{Guid.NewGuid():N}@example.com";
        const string password = "rahasia123";
        var client = CreateClient();

        var reg = await client.PostAsJsonAsync("/api/auth/register", new { email, password });
        reg.EnsureSuccessStatusCode();

        var login = await client.PostAsJsonAsync("/api/auth/login", new { email, password });
        login.EnsureSuccessStatusCode();
        var token = await login.Content.ReadFromJsonAsync<LoginResponse>();

        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token!.AccessToken);
        return client;
    }

    public record LoginResponse(string TokenType, string AccessToken, long ExpiresIn, string RefreshToken);
}

[CollectionDefinition(Name)]
public class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "api";
}
