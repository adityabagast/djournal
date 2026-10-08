using System.Security.Claims;
using DJournal.Api.Data;
using DJournal.Api.Sync;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Connection string disimpan di user-secrets (development) atau
// environment variable ConnectionStrings__Default (server).
var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException(
        "ConnectionStrings:Default belum diatur. Lihat server/README.md.");

builder.Services.AddDbContext<AppDbContext>(o => o
    .UseNpgsql(connectionString)
    .UseSnakeCaseNamingConvention());

// Login pakai ASP.NET Core Identity + bearer token bawaan
// (endpoint /register, /login, /refresh dari MapIdentityApi).
builder.Services.AddAuthorization();
builder.Services
    .AddIdentityApiEndpoints<AppUser>(o =>
    {
        o.User.RequireUniqueEmail = true;
        // Cukup panjang minimal; aturan huruf besar/simbol tidak menambah
        // keamanan berarti dan menyulitkan user (panduan NIST SP 800-63B).
        o.Password.RequiredLength = 8;
        o.Password.RequireNonAlphanumeric = false;
        o.Password.RequireUppercase = false;
        o.Password.RequireLowercase = false;
        o.Password.RequireDigit = false;
    })
    .AddEntityFrameworkStores<AppDbContext>();

builder.Services.Configure<BearerTokenOptions>(IdentityConstants.BearerScheme, o =>
{
    o.BearerTokenExpiration = TimeSpan.FromHours(1);
    o.RefreshTokenExpiration = TimeSpan.FromDays(60);
});

// Kunci enkripsi token disimpan di database supaya token tetap valid
// setelah server restart atau di-deploy ulang.
builder.Services.AddDataProtection()
    .SetApplicationName("djournal")
    .PersistKeysToDbContext<AppDbContext>();

builder.Services.AddProblemDetails();
builder.Services.AddScoped<SyncService>();

// Versi web Flutter di development jalan di port lain, jadi butuh CORS.
// Auth pakai header Bearer (bukan cookie), jadi origin bebas aman di dev.
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
    .AllowAnyOrigin()
    .AllowAnyHeader()
    .AllowAnyMethod()));

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
if (app.Environment.IsDevelopment())
{
    app.UseCors();
}

app.MapGet("/api/health", () => Results.Ok(new { status = "ok" }));

app.MapGroup("/api/auth").MapIdentityApi<AppUser>();

app.MapGet("/api/me", async (ClaimsPrincipal principal, UserManager<AppUser> users) =>
{
    var user = await users.GetUserAsync(principal);
    return user is null
        ? Results.Unauthorized()
        : Results.Ok(new { user.Id, user.Email, user.DisplayName, user.Locale });
}).RequireAuthorization();

app.MapSyncEndpoints();

app.Run();
