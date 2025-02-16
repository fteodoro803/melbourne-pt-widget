# PTV Widget
This application gives users features for easy access to information on PTV. 

The functionality in the Python section is a template, which should be converted to the programming language of whichever Operating System the widget app is for.

### Setup
For the program to work, paste your User/Developer ID and API Key in the config file:
  - Flutter: assets/cfg/config.json

Copy-paste these commands to 
  1. Get dependencies 
     - ```flutter pub get```
  2. Ensure developer credential files don't get tracked by Git 
     - ```git update-index --assume-unchanged flutter_project/assets/cfg/config.json```
     - ```git update-index --assume-unchanged flutter_project/android/secrets.properties```
  3. [Build JSON Serializable files](https://docs.flutter.dev/data-and-backend/serialization/json#running-the-code-generation-utility)
     - ```dart run build_runner build --delete-conflicting-outputs```


### Dependencies
  - crypto 3.0.6
  - global_configuration 2.0.0 
  - http 1.2.2 
  - json_annotation 4.9.0 
  - path_provider 2.1.4

### Notes
- Changes to config.ini __*must*__ not be pushed
- Time from Departures API is in UTC, so it has to be converted to the timezone of the user's device
  - Case: if user's device's time is incorrect
    - match it to the user's device and not actual time;
    - show how many minutes until it arrives, and maybe the time as a subtext (the correct time)
- Flow:
  - Select location
  - Get stops (and transport options) from a Location
    - Select Stop (stop contains tram numbers, name)
  - Choose Direction of Travel
  - Final Selection
- [LucidChart](https://lucid.app/lucidchart/82b010cd-4cd5-42c0-8c19-f3066488b55a/edit?viewport_loc=-1937%2C-126%2C4157%2C2105%2C0_0&invitationId=inv_6c5333c9-7546-45d1-8473-e3fdb2c4135c)
- If modifying Transport or any -info class, make sure to run either:
  - Once: ```dart run build_runner build --delete-conflicting-outputs```
  - Continuously: ```dart run build_runner watch --delete-conflicting-outputs```
- If on Android Studio Ladybug with Gradle Error, get Java JDK 17 and run this on terminal:
  - flutter config --jdk-dir "C:\Program Files\Java\jdk-17"

### To-Do
- Continuous Integration and Development
  - Github Actions
    - https://www.youtube.com/watch?v=scEDHsr3APg
- [PTV Colour Palette](https://www.righttoknow.org.au/request/5149/response/13973/attach/4/PTVH2977%20MSG%202018%202.4%20Colour%20v10%20PA%20v2.pdf)
- [PTV Icons](https://melbournesptgallery.weebly.com/melbourne-tram-sides.html)
- Figure out Disruption and their IDs
  - Particularly in Disruptions
- Calendar Integration
  - ex: I want to take a tram to get to X Location, to arrive at Y time. Add a Notification/Calendar Alert for when they should leave
- API Calls / Data Collection
  - Stops within Distance --> route (id, name, number, type)
    - Get unique PTV Numbers (Tram Numbers, Train, Etc)
  - If I do multiple calls, such as looping to get directions for each Tram Route, does that count as spamming the API? Any way I can minimise calls?
    - Maybe I can create a little text file storing directions for routes, like a cache
- Sort/Reorganise Stop screen
  - maybe add dividers between different stops?

- Ideas
  - For direction, maybe something like "Flinders -> North Coburg"
  - Notification for Disruptions?
    - A way of notifying that a Tram is going to the depot/stops early
    - Cancellation?
  - A setting filtering for PTV with specific descriptors (low floor, aircon, etc)
- Appearance
  - for Android --> Material
  - for Apple --> Cupertino
- Show Disruptions from the Departures (expands=All) 
- Figure out if package: imports are necessary, or if to use normal imports
- Deleting a Transport
  - On the trailing of the Tile, let the user delete it from the transportList, then save to File
- Widget sorts Stops based on closest one
  - If location is always on, if not just keep it custom
- Google Maps
  - [Secure the API Keys](https://github.com/google/secrets-gradle-plugin)

### Testing
- Mockito?
  - Learn how to mock
  - To test how the UI behaves, without reliance on the API

### Decisions
- Every variable will be of String type, because the API handles the numbers in strings

### Bugs
- Buses just seem kinda iffy
  - Maybe remove them for now?
  - The 907 Mitcham bus, for example, returns no data when going towards Mitcham, but does when towards the city
  - But there is data on the PTV Planner and on Google Maps
    - this might be because they get the bus departure times from their database and/or is hardcoded according to the schedule
- Crash when if a Route has a null departure time (may be solved with new Confirmation screen)
  - Example 1:
    - Bus 
    - Location: -37.811359153253406,144.96215876061984
    - Route: 907 Mitcham
- Crash when Selecting a null Bus Route, then going back and selecting another
  - Example 1
    - Bus
    - Location: -37.761665989492705,144.9422826877412
    - Route: 509 Melville Road/Hope Street

<details>
  <summary><h2><b>Python/Template</b></h2></summary>

  ### Setup:
  1. Paste developer credentials in: config.ini
  2. Copy-paste this command
    ```
    git update-index --assume-unchanged template/config.ini
    ```
  3. Dependencies
       - python 3.10
       - requests 2.31.0
       - pytest 8.1.1
       - tzdata

</details>

### References
- [PTV API](https://timetableapi.ptv.vic.gov.au/swagger/ui/index)
- [Sending Data across Screens](https://docs.flutter.dev/cookbook/navigation/passing-data]=)
- [Google Maps API](https://developers.google.com/maps/flutter-package/config#groovy_2)

