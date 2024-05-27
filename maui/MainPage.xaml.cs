using maui.Services;

namespace maui;

public partial class MainPage : ContentPage
{
    int count = 0;
    
    // ptv client
    readonly IPtvApiService _ptv;

    public MainPage(IPtvApiService ptv)
    {
        InitializeComponent();
        _ptv = ptv;
    }

    private async void OnRouteTypeButtonClicked(object sender, EventArgs e)
    {
        ApiLabel.Text = await _ptv.GetRouteTypes();
        UrlLabel.Text = _ptv.GetCurrentUrl();       // ~test
    }
    
    private async void OnRouteDirectionsButtonClicked(object sender, EventArgs e)
    {
        string routeId = RouteIdEntry.Text;
        ApiLabel.Text = await _ptv.GetRouteDirections(routeId);
        UrlLabel.Text = _ptv.GetCurrentUrl();       // ~test
    }
    
    private async void OnStopsButtonClicked(object sender, EventArgs e)
    {
        string location = LocationEntry.Text;
        ApiLabel.Text = await _ptv.GetStops(location);
        UrlLabel.Text = _ptv.GetCurrentUrl();       // ~test
    }
}