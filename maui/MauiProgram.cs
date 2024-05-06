using maui.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;     // For PTV Service injection

namespace maui;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
            });
        
        // PTV Service
        builder.Services.AddSingleton<IPtvApiService, PtvApiService>();     // Singleton bc its fairly simple, program is stateless, just uses inputs (prefs) and spit outputs
        
        // Config file
        builder.Configuration.AddJsonFile("config.json");
        
        // for Automatic Resolution : from https://blog.ewers-peters.de/are-you-using-dependency-injection-in-your-net-maui-app-yet
        builder.Services.AddSingleton<MainPage>();
        

#if DEBUG
        builder.Logging.AddDebug();
#endif

        return builder.Build();
    }
}