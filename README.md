# PTV Widget
This application gives users easy access to information on their selected routes from PTV, via their mobile device's home widget.

# [Demo Video](https://www.youtube.com/watch?v=KVPCm8o5nXM) (as of 28 May 2025)
[![Demo Video](assets/thumbnail.png)](https://www.youtube.com/watch?v=wFH-BXsoAxo)

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
  3. [Build JSON Serializable files](https://docs.flutter.dev/data-and-backend/serialization/json#running-the-code-generation-utility) (use the second if modifying the domain or database files)
     - ```dart run build_runner build --delete-conflicting-outputs```
     - ```dart run build_runner watch --delete-conflicting-outputs```

### Notes
- Changes to config.ini / secrets.properties / AppDelegate.swift __*must*__ not be pushed
- Flow:
  - Select location
  - Get stops (and transport options) from a Location
    - Select Stop (stop contains tram numbers, name)
  - Choose Direction of Travel
  - Final Selection
- [LucidChart](https://lucid.app/lucidchart/82b010cd-4cd5-42c0-8c19-f3066488b55a/edit?viewport_loc=-1937%2C-126%2C4157%2C2105%2C0_0&invitationId=inv_6c5333c9-7546-45d1-8473-e3fdb2c4135c)

### To-Do
- Change the package name (in flutter and android manifest)
- Continuous Integration and Development
- [PTV Colour Palette](https://www.righttoknow.org.au/request/5149/response/13973/attach/4/PTVH2977%20MSG%202018%202.4%20Colour%20v10%20PA%20v2.pdf)
- [PTV Icons](https://melbournesptgallery.weebly.com/melbourne-tram-sides.html)
- Figure out Disruption and their IDs
  - Find a way to see the alternative routes?
- Find way to remove old/removed routes that no longer exist/have no data
- Optimisations
- If Response Data is Null, maybe Refresh 3 times? Then after that, assume it's null
  - Because sometimes, the responses just are null but suddenly work again after

- Ideas
  - Notification for Disruptions?
    - A way of notifying that a Tram is going to the depot/stops early
    - Cancellation?
  - Calendar Integration
    - ex: I want to take a tram to get to X Location, to arrive at Y time. Add a Notification/Calendar Alert for when they should leave
- Figure out if package: imports are necessary, or if to use normal imports
- Google Maps
  - [Secure the API Keys](https://github.com/google/secrets-gradle-plugin)

### Bugs
- Some docklands trams glitch out
- Buses just seem kinda iffy
  - Maybe remove them for now?
  - The 907 Mitcham bus, for example, returns no data when going towards Mitcham, but does when towards the city
  - But there is data on the PTV Planner and on Google Maps
    - this might be because they get the bus departure times from their database and/or is hardcoded according to the schedule

### References
- [PTV API](https://timetableapi.ptv.vic.gov.au/swagger/ui/index)
- [Google Maps API](https://developers.google.com/maps/flutter-package/config#groovy_2)

