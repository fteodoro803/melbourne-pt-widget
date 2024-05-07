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

    private async void OnButtonClicked(object sender, EventArgs e)
    {
        // Sample counter button
        count++;
        CounterBtn.Text = count == 1 ? $"Clicked {count} time" : $"Clicked {count} times";

        List<(string, string)> testParameters =
        [
            ("John", "Doe"),
            ("Alice", "Smith"),
            ("Bob", "Johnson")

        ];
        
        ApiLabel.Text = await _ptv.GetRouteTypes();
        UrlLabel.Text = _ptv.GetCurrentUrl();       // ~test
    }
}