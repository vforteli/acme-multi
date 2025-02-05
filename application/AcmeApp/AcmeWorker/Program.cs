using Azure.Identity;
using Azure.Messaging.ServiceBus;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();
builder.Logging.AddSimpleConsole(c => c.SingleLine = true);
builder.Logging.SetMinimumLevel(LogLevel.Information);

var app = builder.Build();

const string queueName = "something-happened";

app.UseSwagger();
app.UseSwaggerUI();

app.MapHealthChecks("/health").WithOpenApi();
var logger = app.Services.GetRequiredService<ILogger<Program>>();

await using var serviceBusClient =
    new ServiceBusClient(Environment.GetEnvironmentVariable("SB_ENDPOINT"), new DefaultAzureCredential());

await using var receiver = serviceBusClient.CreateReceiver(queueName);


app.MapGet("/api/dostuff", (string text) =>
    {
        logger.LogInformation("Got message from backend");
        return $"hello from worker {Environment.MachineName}...";
    })
    .WithOpenApi();


var receiveTask = Task.Factory.StartNew(async () =>
{
    logger.LogInformation("Waiting for messages on queue '{queue}'...", queueName);

    while (true)
    {
        // well actually this should probably use batching etc.. but easier to test with a single message
        var message = await receiver.ReceiveMessageAsync(TimeSpan.FromSeconds(20));

        if (message == null)
        {
            break;
        }

        logger.LogInformation("Received messageId: {messageId}, body: {body}", message.MessageId, message.Body);
        await receiver.CompleteMessageAsync(message);
    }
});

app.Run();