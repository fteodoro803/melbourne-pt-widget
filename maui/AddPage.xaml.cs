using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using maui.Services;

namespace maui;

public partial class AddPage : ContentPage
{
    // ptv client
    readonly IPtvApiService _ptv;
    
    public AddPage(IPtvApiService ptv)
    {
        InitializeComponent();
        _ptv = ptv;
    }
    
    //* Navigation *//
    // AddPage
    private async void MainPageClicked(object sender, EventArgs e)
    {
        await Shell.Current.GoToAsync("///MainPage");
    }
}