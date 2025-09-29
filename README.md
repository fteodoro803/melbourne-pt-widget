# PTV Widget
This application gives users easy access to information on their selected routes from PTV, via their mobile device's home widget.

# [Demo Video](https://www.youtube.com/watch?v=wFH-BXsoAxo) (as of 28 May 2025)
<a href="https://www.youtube.com/watch?v=wFH-BXsoAxo">
  <img src="assets/thumbnail.png" alt="Watch the demo" width="400" />
</a>

### Setup
For the program to work, paste your User ID and/or API Key in the config file:
  - Base app: PTV and Google Maps credentials: assets/cfg/config.json
  - Android widget: Google Maps credentials: android/secrets.properties
  - iOS widget: Google Maps credentials: ios/Runner/AppDelegate.swift

Copy-paste these commands to 
  1. Get dependencies 
     - ```flutter pub get```
  2. Ensure developer credential files don't get tracked by Git 
     - ```git update-index --assume-unchanged assets/cfg/config.json android/secrets.properties ios/Runner/AppDelegate.swift```
  3. [Build JSON Serializable files](https://docs.flutter.dev/data-and-backend/serialization/json#running-the-code-generation-utility) (Use either of the following two)
     - On initial build (once)
       - ```dart run build_runner build --delete-conflicting-outputs```
     - If modifying the domain or database files (continuous)
       - ```dart run build_runner watch --delete-conflicting-outputs```

### Notes
- Changes to config.ini / secrets.properties / AppDelegate.swift __*must*__ not be pushed
- [LucidChart](https://lucid.app/lucidchart/82b010cd-4cd5-42c0-8c19-f3066488b55a/edit?viewport_loc=-1937%2C-126%2C4157%2C2105%2C0_0&invitationId=inv_6c5333c9-7546-45d1-8473-e3fdb2c4135c)

### To-Do
- [PTV Colour Palette](https://www.righttoknow.org.au/request/5149/response/13973/attach/4/PTVH2977%20MSG%202018%202.4%20Colour%20v10%20PA%20v2.pdf)
- [PTV Icons](https://melbournesptgallery.weebly.com/melbourne-tram-sides.html)
- Google Maps

### References
- [PTV API](https://timetableapi.ptv.vic.gov.au/swagger/ui/index)
- [Google Maps API](https://developers.google.com/maps/flutter-package/config#groovy_2)

