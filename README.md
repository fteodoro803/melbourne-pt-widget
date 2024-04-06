# PTV Widget
This application gives users features for easy access to information on PTV. 

The functionality here is a template, which should be converted to the programming language of whichever Operating System contains the widget.

### Setup
For the program to work, paste your User/Developer ID and API Key in the *config.ini* file. 

### Dependencies
- python 3.10
- requests 2.31.0
- pytest 8.1.1

### Notes
- api.py
  - URL signatures are order-dependent
    - make sure parameters are in order according to PTV API site
    - Request seems to end in a Question Mark, and any parameter after that has an And sign, but only to the additional ones.
      - https://timetableapi.ptv.vic.gov.au/v3/stops/location/latitude,longitude?route_types=1&max_results=100&devid=yourID&signature=yourSignature
- Time from Departures API is in UTC, so it has to be converted to the timezone of the user's device
  - Case: if user's device's time is incorrect
    - match it to the user's device and not actual time;
    - show how many minutes until it arrives, and maybe the time as a subtext (the correct time)

### To-Do
- Priority: 
  - Trams based on Location, and Direction
  - Selecting 1 form of PTV and getting information on that to Widget:
    1. Big Widget (saving a stop)
       1. ![tram_sample_screen.jpg](images%2Ftram_sample_screen.jpg)
    2. Small Widget (saving a tram)
       1. just one of the above
- Get functionality to work on all public transport
- Setup Screens
  - Home Address
  - Destination Address
- What if 2+ forms of PTV are needed to get to a destination?
- Figure out Disruption and their IDs
  - Particularly in Disruptions
- Calendar Integration
  - ex: I want to take a tram to get to X Location, to arrive at Y time. Add a Notification/Calendar Alert for when they should leave
- Flow:
  - Select location
  - Get stops (and transport options) from a Location
    - Select Stop (stop contains tram numbers, name)
  - Choose Direction of Travel
  - Final Selection
- API Calls / Data Collection
  - Stops within Distance --> route (id, name, number, type)
    - Get unique PTV Numbers (Tram Numbers, Train, Etc)
  - If I do multiple calls, such as looping to get directions for each Tram Route, does that count as spamming the API? Any way I can minimise calls?
    - Maybe I can create a little text file storing directions for routes, like a cache

### Testing
- PyTest
- apiTests.py
  - Can't really do tests on valid/invalid URLS, since that's done by the API, but include these responses as tests maybe???
  - Maybe some tests for, if the site is down or something