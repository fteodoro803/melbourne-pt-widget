using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;  // testing geting config.json

using System.Text;
using System.Web;
using System.Security.Cryptography;
using Newtonsoft.Json.Linq;


namespace maui.Services;

// IN EACH OF THE PTV CALL FUNCTIONS, MAKE SURE TO LOAD THE USER'S PREFERENCES //

public class PtvApiService : IPtvApiService
{
    // API Credentials
    // private readonly IConfiguration _config;
    private readonly string _userId;
    private readonly string _apiKey;
    
    // Test Values
    private string? _url;

    public PtvApiService(IConfiguration config)
    {
        if (config == null)
        {
            throw new SystemException("config does not exist / is empty");
        }
        
        // _config = config;
        _userId = config["DEVELOPER_CREDENTIALS:USER_ID"] ?? string.Empty;
        _apiKey = config["DEVELOPER_CREDENTIALS:API_KEY"] ?? string.Empty;
    }

    
    public string GetUrl(string request, List<(string, string)>? parameters = null)
    {
        if (parameters == null)
        {
            parameters = new List<(string, string)>();
        }

        // Base URL
        // var urlHttp = "http://timetableapi.ptv.vic.gov.au";
        var urlHttps = "https://timetableapi.ptv.vic.gov.au";
        
        // Encode the api_key and message to bytes
        var keyBytes = Encoding.UTF8.GetBytes(_apiKey);
        parameters.Add(("devid", _userId));
        var signatureValueParameters = HttpUtility.UrlEncode(BuildQueryString(parameters));
        signatureValueParameters = signatureValueParameters.Replace("%3d", "=");     // for human readability
        var signatureValue = $"{request}?{signatureValueParameters}";     // "The signature value is a HMAC-SHA1 hash of the completed request (minus the base URL but including your user ID, known as “devid”) and the API key"
        var messageBytes = Encoding.UTF8.GetBytes(signatureValue);
        
        // Generate HMAC SHA1 signature
        using (var hmacSha1 = new HMACSHA1(keyBytes))
        {
            var hashBytes = hmacSha1.ComputeHash(messageBytes);
            var signature = BitConverter.ToString(hashBytes).Replace("-", "").ToUpper();
            parameters.Add(("signature", signature));
        }

        // URL
        var encodedParameters = BuildQueryString(parameters);  // adds parameters to url
        var url = $"{urlHttps}/{request}?{encodedParameters}";
        Console.WriteLine($"Url: {url}");    // ~test
        _url = url;     // ~test
        return url;
    }
    
    // Helper method to build query string
    private static string BuildQueryString(List<(string, string)> parameters)
    {
        var queryString = new StringBuilder();
        foreach (var (key, value) in parameters)
        {
            if (queryString.Length > 0)
            {
                queryString.Append("&");
            }
            queryString.Append($"{key}={HttpUtility.UrlEncode(value)}");
        }
        return queryString.ToString();
    }

    // Gets Route Size
    public async Task<string> GetRouteTypes() // should be a Response equivalent type, not string 
    {
        string url = GetUrl("/v3/route_types");
        return await FetchParsedJson(url);
    }
    
    // Gets Route Directions
    public async Task<string> GetRouteDirections(string? routeId) // should be a Response equivalent type, not string 
    {
        if (routeId == null) {return "Route ID should not be Null";}    // Early Exit Case
        int routeIdInt = int.Parse(routeId);
        string url = GetUrl($"/v3/directions/route/{routeIdInt}");
        return await FetchParsedJson(url);
    }
    
    // Getting Stops based on Location
    public async Task<string> GetStops(string? location, List<int>? routeTypes = null, int? maxResults = null, int? maxDistance = null)
    {
        if (location == null) {return "Location should not be Null";}    // Early Exit Case
        
        string[] locations = location.Split(",");
        if (locations.Length != 2)
        {
            return "Location should be in the format 'latitude,longitude'";    // Early Exit Case
        }

        if (!double.TryParse(locations[0], out double latitude))
        {
            return "Invalid latitude";    // Early Exit Case
        }

        if (!double.TryParse(locations[1], out double longitude))
        {
            return "Invalid longitude";    // Early Exit Case
        }
        
        // Parameter Handling
        var parameters = new List<(string, string)>();

        if (routeTypes != null)
        {
            foreach (var typeInt in routeTypes)
            {
                parameters.Add(("route_types", typeInt.ToString()));
            }
        }

        if (maxResults != null)
        {
            parameters.Add(("max_results", maxResults.ToString() ?? string.Empty));     // ensures that the parameter is non-empty
        }

        if (maxDistance != null)
        {
            parameters.Add(("max_distance", maxDistance.ToString() ?? string.Empty));
        }

        // PTV API request
        string url = GetUrl($"/v3/stops/location/{latitude},{longitude}", parameters);
        return await FetchParsedJson(url);
    }
    
    // // GET DEPARTURES UNEDITED
    // public async Task<string> Departures(int routeType, int stopId, int? routeId = null, int? directionId = null, DateTime? dateUtc = null, int? maxResults = null, List<string> expand = null)
    //     {
    //         var parameters = new List<(string, string)>();
    //
    //         // Direction
    //         if (directionId.HasValue)
    //         {
    //             parameters.Add(("direction_id", directionId.Value.ToString()));
    //         }
    //
    //         // Date
    //         if (dateUtc.HasValue)
    //         {
    //             parameters.Add(("date_utc", dateUtc.Value.ToString("yyyy-MM-ddTHH:mm:ssZ")));
    //         }
    //
    //         // Max Results
    //         if (maxResults.HasValue)
    //         {
    //             parameters.Add(("max_results", maxResults.Value.ToString()));
    //         }
    //
    //         // Expands
    //         if (expand != null)
    //         {
    //             foreach (var expandStr in expand)
    //             {
    //                 parameters.Add(("expand", expandStr));
    //             }
    //         }
    //
    //         // PTV API request
    //         string url;
    //         if (routeId.HasValue)
    //         {
    //             if (parameters.Count >= 1)
    //             {
    //                 url = GetUrl($"/v3/departures/route_type/{routeType}/stop/{stopId}/route/{routeId}", parameters);
    //             }
    //             else
    //             {
    //                 url = GetUrl($"/v3/departures/route_type/{routeType}/stop/{stopId}/route/{routeId}");
    //             }
    //         }
    //         else
    //         {
    //             if (parameters.Count >= 1)
    //             {
    //                 url = GetUrl($"/v3/departures/route_type/{routeType}/stop/{stopId}", parameters);
    //             }
    //             else
    //             {
    //                 url = GetUrl($"/v3/departures/route_type/{routeType}/stop/{stopId}");
    //             }
    //         }
    //         
    //         using (HttpClient client = new HttpClient())
    //         {
    //             HttpResponseMessage response = await client.GetAsync(url);
    //             string jsonResponse = await response.Content.ReadAsStringAsync();
    //             string parsedJson = JToken.Parse(jsonResponse).ToString(Formatting.Indented);        // Parsing and Formatting the JSON Response for readability
    //             return parsedJson;
    //         }
    //     }

    // Maybe add a Function for the "using httpclient return parsedJson" bit
    private async Task<string> FetchParsedJson(string url)
    {
        using (HttpClient client = new HttpClient())
        {
            HttpResponseMessage response = await client.GetAsync(url);
            string jsonResponse = await response.Content.ReadAsStringAsync();
            string parsedJson = JToken.Parse(jsonResponse).ToString(Formatting.Indented);        // Parsing and Formatting the JSON Response for readability
            return parsedJson;
        }
    }
    
    // TEST
    public string GetCurrentUrl()
    {
        return _url ?? "NO URL";
    }
}