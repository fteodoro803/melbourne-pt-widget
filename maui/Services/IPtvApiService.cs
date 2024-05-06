namespace maui.Services;

public interface IPtvApiService
{
    Task<string> GetUrl();
    string GetApiCredentials();

}