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
- Features.py
  - URL signatures are order-dependent
    - make sure parameters are in order according to PTV API site
    - Request seems to end in a Question Mark, and any parameter after that has an And sign, but only to the additional ones.
      - https://timetableapi.ptv.vic.gov.au/v3/stops/location/latitude,longitude?route_types=1&max_results=100&devid=yourID&signature=yourSignature

### To-Do
- Priority: 
  - Trams based on Location, and Direction
  - Selecting 1 form of PTV and getting information on that to Widget
- Get functionality to work on all public transport
- Setup Screens
  - Home Address
  - Destination Address
- What if 2+ forms of PTV are needed to get to a destination?

### Testing
- PyTest
- Features.py
  - Can't really do tests on valid/invalid URLS, since that's done by the API, but include these responses as tests maybe???
  - Maybe some tests for, if the site is down or something