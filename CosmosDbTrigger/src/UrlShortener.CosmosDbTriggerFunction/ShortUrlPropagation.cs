using System;
using System.Collections.Generic;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace UrlShortener.CosmosDbTriggerFunction
{
    public class ShortUrlPropagation
    {
        private readonly Container _container;
        private readonly ILogger _logger;

        public ShortUrlPropagation(ILoggerFactory loggerFactory, Container container)
        {
            _container = container;
            _logger = loggerFactory.CreateLogger<ShortUrlPropagation>();
        }

        [Function("ShortUrlPropagation")]
        public async Task Run([CosmosDBTrigger(
                databaseName: "urls",
                containerName: "items",
                Connection = "CosmosDbConnection",
                LeaseContainerName = "leases",
                CreateLeaseContainerIfNotExists = true)]
            IReadOnlyList<UrlDocument> input)
        {
            if (input == null || input.Count <= 0) return;
            
            foreach (var document in input)
            {
                _logger.LogInformation("Short Url: {ShortUrl}", document.Id);
                try
                {
                    var cosmosDbDocument = new ShortenedUrlEntity(
                        document.LongUrl,
                        document.Id,
                        document.CreatedOn,
                        document.CreatedBy
                    );
                    await _container.UpsertItemAsync(cosmosDbDocument, new PartitionKey(document.CreatedBy));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error writing to Cosmos DB");
                    throw;
                }
            }
        }
    }

    public class UrlDocument
    {
        public string Id { get; set; }
        public DateTimeOffset CreatedOn { get; set; }
        public string CreatedBy { get; set; }
        public string LongUrl { get; set; }
    }
    public class ShortenedUrlEntity
    {
        public string LongUrl { get; }

        [JsonProperty(PropertyName = "id")] // Cosmos DB Unique Identifier
        public string ShortUrl { get; }

        public DateTimeOffset CreatedOn { get; }

        [JsonProperty(PropertyName = "PartitionKey")] // Cosmos DB Partition Key
        public string CreatedBy { get; }

        public ShortenedUrlEntity(string longUrl, string shortUrl, 
            DateTimeOffset createdOn, string createdBy)
        {
            LongUrl = longUrl;
            ShortUrl = shortUrl;
            CreatedOn = createdOn;
            CreatedBy = createdBy;
        }
    }
}