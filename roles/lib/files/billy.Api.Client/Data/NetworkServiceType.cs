using System.Text.Json.Serialization; 
using Newtonsoft.Json;

namespace billy.Api.Data
{
    public class NetworkServiceType
    {
        [JsonProperty("name"), JsonPropertyName("name")]
        public string Name { get; set; } = "";
    }
}
