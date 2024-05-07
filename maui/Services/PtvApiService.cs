using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;  // testing geting config.json

using System.Text;
using System.Web;
using System.Collections.Generic;
using System.Net.Http;
using System.Security.Cryptography;


namespace maui.Services;

// IN EACH OF THE PTV CALL FUNCTIONS, MAKE SURE TO LOAD THE USER'S PREFERENCES //

public class PtvApiService : IPtvApiService
{
    // API Credentials
    private readonly IConfiguration _config;
    private readonly string _userID;
    private readonly string _apiKey;
    
    // Test Values
    private string _url;

    public PtvApiService(IConfiguration config)
    {
        _config = config;
        _userID = config["DEVELOPER_CREDENTIALS:USER_ID"];
        _apiKey = config["DEVELOPER_CREDENTIALS:API_KEY"];

        if (config == null)
        {
            throw new SystemException("config does not exist / is empty");
        }

        if (_userID.Length == 0 || _apiKey.Length == 0)
        {
            throw new SystemException("USER_ID or API_KEY is empty");
        }
    }

    
    public string GetUrl(string request, List<(string, string)> parameters = null)
    {
        if (parameters == null)
        {
            parameters = new List<(string, string)>();
        }

        // Base URL
        var urlHttp = "http://timetableapi.ptv.vic.gov.au";
        var urlHttps = "https://timetableapi.ptv.vic.gov.au";
        
        // Encode the api_key and message to bytes
        var keyBytes = Encoding.UTF8.GetBytes(_apiKey);
        parameters.Add(("devid", _userID));
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

    public async Task<string> GetRouteTypes() // should be a Resposne equivalent type, not string 
    {
        string url = GetUrl("/v3/route_types");

        using (HttpClient client = new HttpClient())
        {
            HttpResponseMessage response = await client.GetAsync(url);
            string jsonResponse = await response.Content.ReadAsStringAsync();
            
            return jsonResponse;
        }
    }
    
    // TEST
    public string GetCurrentUrl()
    {
        return _url;
    }
}