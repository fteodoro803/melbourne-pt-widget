from datetime import datetime, timezone
import json

import requests
from api import getURL, getRouteTypes, getStopsByLocation, getRouteDirections, getDepartures
from utilities import convertUTCtoLocalTime, convertDepartureTimesToLocalTime


# Test Variables
# Hope Street
latitude, longitude = -37.761665989492705, 144.9422826877412
route_type = 1
route_types = [1]
route_id = 11529
max_results = 5
max_distance = 300
stop_id = 3086
direction_id = 21   # towards city


# Function Testing

# # Get Route Types
# route_types = getRouteTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# # Test Latitude and Longitude
# stops = getStopsByLocation(latitude, longitude, route_types=route_types, max_results=max_results, max_distance=max_distance)
# print(f"Stops: \n{json.dumps(stops.json(), indent=2)} \n")

# Test Getting Route Directions
print(f"Directions for Route {route_id}: \n{json.dumps(getRouteDirections(route_id).json(), indent=2)} \n")

# Test Departures
expands = None
departures = getDepartures(route_type, stop_id, route_id, direction_id=direction_id, max_results=5)    # JSON File
new_departures = convertDepartureTimesToLocalTime(departures.json())
print(f"Departures for stopID {stop_id}, routeType {route_type}: \n{json.dumps(new_departures, indent=4)} \n")


