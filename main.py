from datetime import datetime, timezone
import json

import requests
import ptv_api as ptv
import utilities


# Test Variables #

# Hope Street
latitude, longitude = -37.761665989492705, 144.9422826877412
route_type = 1
route_types = [1]
route_id = 11529
max_results = 5
max_distance = 300
stop_id = 3086
direction_id = 21   # towards city

# # Queen Vic Market
# latitude, longitude = -37.80607940323542, 144.95735362615287
# route_type = 1
# route_types = [1]
# max_results = 5
# max_distance = 300
# route_id = 725
# route_ids = [725, 887, 897]     # 19, 57, 59


# Function Testing

# # Get Route Types
# route_types = ptv.routeTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# # Test Latitude and Longitude  --> get stop that we want
# stops = ptv.stops(latitude, longitude, route_types=route_types, max_results=max_results, max_distance=max_distance)
# print(f"Stops: \n{json.dumps(stops.json(), indent=2)} \n")

# # Test Getting Route Directions   --> from stop, get directions
# print(f"Directions for Route {route_id}: \n{json.dumps(ptv.routeDirections(route_id).json(), indent=2)} \n")

# Test Departures
expands = None
departures = ptv.departures(route_type, stop_id, route_id, direction_id=direction_id, max_results=5)    # JSON File
new_departures = utilities.convertDepartureTimesToLocalTime(departures.json())
print(f"Departures for stopID {stop_id}, routeType {route_type}: \n{json.dumps(new_departures, indent=4)} \n")


