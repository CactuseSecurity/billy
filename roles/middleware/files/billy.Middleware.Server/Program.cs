using billy.Api.Client;
using billy.Api.Client.Queries;
using billy.Config.File;
using billy.Logging;
using billy.Middleware.Server;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Reflection;

// Implicitly call static constructor so backround lock process is started
// (static constructor is only called after class is used in any way)
Log.WriteInfo("Startup", "Starting billy Middleware Server...");

object changesLock = new object(); // LOCK

// ReportScheduler reportScheduler;
// AutoDiscoverScheduler autoDiscoverScheduler;
// DailyCheckScheduler dailyCheckScheduler;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls(ConfigFile.MiddlewareServerNativeUri ?? throw new Exception("Missing middleware server url on startup."));

// Create Token Generator
JwtWriter jwtWriter = new JwtWriter(ConfigFile.JwtPrivateKey);

// Create JWT for middleware-server API calls (relevant part is the role middleware-server) and add it to the Api connection header. 
ApiConnection apiConnection = new GraphQlApiConnection(ConfigFile.ApiServerUri ?? throw new Exception("Missing api server url on startup."), jwtWriter.CreateJWTMiddlewareServer());

// Fetch all connectedLdaps via API (blocking).
List<Ldap> connectedLdaps = new List<Ldap>();
int connectionAttemptsCount = 1;
while (true)
{
    // Repeat first api call in case graphql api is not started yet
    try
    {
        connectedLdaps = apiConnection.SendQueryAsync<List<Ldap>>(AuthQueries.getAllLdapConnections).Result;
        break;
    }
    catch (Exception ex)
    {
        Log.WriteError("Graphql api", "Graphql api unreachable.", ex);
        Thread.Sleep(500 * connectionAttemptsCount++);
    }
}

Action<Exception> handleSubscriptionException = (Exception exception) => Log.WriteError("Subscription", "Subscription lead to exception.", exception);
GraphQlApiSubscription<List<Ldap>>.SubscriptionUpdate connectedLdapsSubscriptionUpdate = (List<Ldap> ldapsChanges) => { lock (changesLock) { connectedLdaps = ldapsChanges; } };
GraphQlApiSubscription<List<Ldap>> connectedLdapsSubscription = apiConnection.GetSubscription<List<Ldap>>(handleSubscriptionException, connectedLdapsSubscriptionUpdate, AuthQueries.getLdapConnectionsSubscription);
Log.WriteInfo("Found ldap connection to server", string.Join("\n", connectedLdaps.ConvertAll(ldap => $"{ldap.Address}:{ldap.Port}")));

// Create and start report scheduler
// Task.Factory.StartNew(() =>
// {
//     reportScheduler = new ReportScheduler(apiConnection, jwtWriter, connectedLdapsSubscription);
// }, TaskCreationOptions.LongRunning);

// // Create and start auto disovery scheduler
// Task.Factory.StartNew(async() =>
// {
//     autoDiscoverScheduler = await AutoDiscoverScheduler.CreateAsync(apiConnection);
// }, TaskCreationOptions.LongRunning);

// // Create and start daily check scheduler
// Task.Factory.StartNew(async() =>
// {
//     dailyCheckScheduler = await DailyCheckScheduler.CreateAsync(apiConnection);
// }, TaskCreationOptions.LongRunning);

// Add services to the container.
builder.Services.AddControllers()
  .AddJsonOptions(jsonOptions =>
  {
        //jsonOptions.JsonSerializerOptions.PropertyNameCaseInsensitive = true;
        jsonOptions.JsonSerializerOptions.PropertyNamingPolicy = null;
  });

builder.Services.AddSingleton<JwtWriter>(jwtWriter);
builder.Services.AddSingleton<List<Ldap>>(connectedLdaps);
builder.Services.AddScoped<ApiConnection>(_ => new GraphQlApiConnection(ConfigFile.ApiServerUri, jwtWriter.CreateJWTMiddlewareServer()));

builder.Services.AddAuthentication(confOptions =>
{
    confOptions.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    confOptions.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(confOptions =>
{
    confOptions.TokenValidationParameters = new TokenValidationParameters
    {
        RequireExpirationTime = true,
        RequireSignedTokens = true,
        ValidateAudience = false,
        ValidateIssuer = false,
        ValidateLifetime = true,
        RoleClaimType = "role",
        IssuerSigningKey = ConfigFile.JwtPublicKey
    };
});
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "billy Middleware API Documentation",
        Description = "A documentation of the REST API interface for the billy Middleware.",
        Version = "v1"
    });
    string documentationPath = Path.Combine(AppContext.BaseDirectory, $"{Assembly.GetExecutingAssembly().GetName().Name}.xml");
    c.IncludeXmlComments(documentationPath);
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseSwagger();
app.UseSwaggerUI(c => { c.SwaggerEndpoint("/swagger/v1/swagger.json", "billy.Middleware v1"); });

//app.UseHttpsRedirection();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.UseEndpoints(endpoints =>
{
    endpoints.MapControllers();
});

app.Run();