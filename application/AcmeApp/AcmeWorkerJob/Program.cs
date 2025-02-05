using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;

const string queueName = "something-happened";

var loggerFactory = LoggerFactory.Create(o =>
{
    o.SetMinimumLevel(LogLevel.Information);
    o.AddSimpleConsole(c => { c.SingleLine = true; });
});

var logger = loggerFactory.CreateLogger<Program>();

await using var serviceBusClient = new ServiceBusClient(
    Environment.GetEnvironmentVariable("SB_ENDPOINT"),
    new DefaultAzureCredential());

await using var receiver = serviceBusClient.CreateReceiver(queueName);

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

logger.LogInformation("No more message on queue '{queue}', going back to sleep...", queueName);