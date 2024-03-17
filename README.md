# PTV Widget
This application gives users features for easy access to information on PTV. 

The functionality here is a base, which should be converted to the programming language of whichever Operating System contains the widget.

### To-Do
- Priority: Trams
- Get functionality to work on all public transport

### Setup
For the program to work, paste your User/Developer ID and API Key in the *config.ini* file. 

### Dependencies
- python 3.10
- requests 2.31.0
- pytest 8.1.1

### Testing Notes
- PyTest
- Features
  - Can't really do tests on valid/invalid URLS, since that's done by the API, but include these responses as tests maybe???
  - Maybe some tests for, if the site is down or something 
