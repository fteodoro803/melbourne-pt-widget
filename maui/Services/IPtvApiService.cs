namespace maui.Services;

public interface IPtvApiService
{
    // string GetUrl(string request);
    string GetUrl(string request, List<(string, string)> parameters);
    Task<string> GetRouteTypes();
    Task<string> GetRouteDirections(string routeId);      // should have a route id arg

    Task<string> GetStops(string location, List<int>? routeTypes = null, int? maxResults = null,        // convert these into string types, then do conversion later
        int? maxDistance = null);
    
    // test
    public string GetCurrentUrl();
}