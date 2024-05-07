namespace maui.Services;

public interface IPtvApiService
{
    // string GetUrl(string request);
    string GetUrl(string request, List<(string, string)> parameters);
    Task<string> GetRouteTypes();
    
    // test
    public string GetCurrentUrl();
}