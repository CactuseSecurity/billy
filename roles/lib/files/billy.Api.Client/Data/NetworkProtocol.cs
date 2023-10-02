using System.Text.Json.Serialization; 
using Newtonsoft.Json;

namespace billy.Api.Data
{
    public class NetworkProtocol
    {
        [JsonProperty("id"), JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonProperty("name"), JsonPropertyName("name")]
        public string Name { get; set; } = "";
    }
}
