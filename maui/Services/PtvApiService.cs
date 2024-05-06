using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;  // testing geting config.json

namespace maui.Services;

// IN EACH OF THE PTV CALL FUNCTIONS, MAKE SURE TO LOAD THE USER'S PREFERENCES //

public class PtvApiService : IPtvApiService
{
    // API Credentials
    private readonly IConfiguration _config;
    private readonly string _userID;
    private readonly string _apiKey;
    
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
        return _userID;
    }
}