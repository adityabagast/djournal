using System.Security.Claims;

namespace DJournal.Api.Sync;

public static class SyncEndpoints
{
    public static RouteGroupBuilder MapSyncEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/sync").RequireAuthorization();

        group.MapPost("/push", async (SyncPushRequest req, ClaimsPrincipal user, SyncService sync, CancellationToken ct) =>
        {
            try
            {
                return Results.Ok(await sync.PushAsync(user.GetUserId(), req, ct));
            }
            catch (SyncValidationException ex)
            {
                return Results.Problem(ex.Message, statusCode: StatusCodes.Status400BadRequest);
            }
        });

        group.MapGet("/pull", async (long? since, ClaimsPrincipal user, SyncService sync, CancellationToken ct) =>
            Results.Ok(await sync.PullAsync(user.GetUserId(), since ?? 0, ct)));

        return group;
    }

    public static Guid GetUserId(this ClaimsPrincipal user) =>
        Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new InvalidOperationException("User belum login."));
}
