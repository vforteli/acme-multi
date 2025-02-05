using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Files.DataLake;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();
builder.Services.AddHttpClient();
builder.Logging.AddSimpleConsole(c => c.SingleLine = true);
builder.Logging.SetMinimumLevel(LogLevel.Information);

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

using var httpClient = new HttpClient();

// lul :D
const string connectionString =
    "https://seflsefhf.blob.core.windows.net/?sv=2022-11-02&ss=bfqt&srt=sco&sp=rwdlacupyx&se=2025-06-19T03:07:28Z&st=2025-01-17T20:07:28Z&spr=https&sig=IGIeLxL4ZyTwJIMJxfGM0hUzu6YH0SwtKh3z1%2FhydRA%3D";

var datalakeServiceClient = new DataLakeServiceClient(new Uri(connectionString));

await using var serviceBusClient =
    new ServiceBusClient(Environment.GetEnvironmentVariable("SB_ENDPOINT"), new DefaultAzureCredential());

await using var sender = serviceBusClient.CreateSender("something-happened");

app.MapHealthChecks("/health").WithOpenApi();

app.MapGet("/api/dostuff", (string text) => "hello from backend").WithOpenApi();

app.MapGet("/api/pingworker", async () =>
    {
        var response = await httpClient.GetAsync("http://worker-service/api/dostuff?text=hello");
        var content = await response.Content.ReadAsStringAsync();
        return "yeeap: " + content;
    })
    .WithOpenApi();

app.MapGet("/api/testdatalake", async () =>
    {
        var response = await datalakeServiceClient.GetFileSystemClient("somecontainer").GetFileClient("foo.txt")
            .ReadContentAsync();
        var content = response.Value.Content.ToString();
        return content;
    })
    .WithOpenApi();

app.MapGet("/api/testdatalakewif", async () =>
    {
        var wifClient = new DataLakeServiceClient(
            new Uri("https://seflsefhf.blob.core.windows.net/"),
            new DefaultAzureCredential());

        var response = await wifClient.GetFileSystemClient("somecontainer").GetFileClient("foo.txt")
            .ReadContentAsync();

        var content = response.Value.Content.ToString();
        return content;
    })
    .WithOpenApi();

app.MapGet("/api/sendmessage",
        async () =>
        {
            await sender.SendMessageAsync(new ServiceBusMessage("sup: " + DateTime.UtcNow));
            return $"yup, send message to: {sender.FullyQualifiedNamespace}";
        })
    .WithOpenApi();

app.Run();