using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;  // testing geting config.json

namespace maui.Services;

// IN EACH OF THE PTV CALL FUNCTIONS, MAKE SURE TO LOAD THE USER'S PREFERENCES //

public class PtvApiService : IPtvApiService
{
    private readonly IConfiguration _config;

    public PtvApiService(IConfiguration config)
    {
        _config = config;
    }

    public Task<string> GetUrl()
    {
        return null;
    }
    
    public async Task<string> GetUrlTest()
    {
        const string url = "STRING";
        return await Task.FromResult(url);
    }

    public string GetApiCredentials()
    {
        // Getting config.json
        var configValues = _config.AsEnumerable();
        
        // Converting to String
        var jsonString = JsonConvert.SerializeObject(configValues, Formatting.Indented);
        
        Console.WriteLine(jsonString);
        return jsonString;
    }
}