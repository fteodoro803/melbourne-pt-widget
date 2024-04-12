from datetime import datetime, timezone
import json

import requests
import ptv_api as ptv
import utilities
import functionality

# Test Variables #

# # Hope Street
# latitude, longitude = -37.761665989492705, 144.9422826877412
# route_type = 1
# route_types = [1]
# route_id = 11529
# max_results = 5
# max_distance = 300
# stop_id = 3086
# direction_id = 21   # towards city

# # Queen Vic Market
# latitude, longitude = -37.80607940323542, 144.95735362615287
# route_type = 1
# route_types = [1]
# max_results = 5
# max_distance = 300
# stop_id = 2258
# route_id = 725
# route_ids = [725, 887, 897]     # 19, 57, 59

# Melb Central
latitude, longitude = -37.811359153253406, 144.96215876061984
route_types = [0,1]
max_results = 1
max_distance = 500
route_type = 1      # tram
stop_id = 2718      # tram
# route_type = 0      # train
# stop_id = 1120      # train

# API Testing #

# # Get Route Types
# route_types = ptv.routeTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# # Test Latitude and Longitude  --> get stop that we want
# stops = ptv.stops(latitude, longitude, route_types=route_types, max_results=max_results, max_distance=max_distance)
# print(f"Stops: \n{json.dumps(stops.json(), indent=2)} \n")

# # Test Getting Route Directions   --> from stop, get directions
# print(f"Directions for Route {route_id}: \n{json.dumps(ptv.routeDirections(route_id).json(), indent=2)} \n")

# Test Departures
# expands = None
# expands = ["Direction", "Stop", "Route"]
expands = ["Direction", "Disruption", "Stop", "Route", "VehicleDescription"]
# expands = ["All"]
# departures = ptv.departures(route_type, stop_id, route_id, max_results=3, expand=expands)    # JSON File
departures = ptv.departures(route_type, stop_id, max_results=1, expand=expands)    # JSON File , no Direction ID, no Route ID
new_departures = utilities.convertDepartureTimesToLocalTime(departures.json())
print(f"Departures for stopID {stop_id}, routeType {route_type}: \n{json.dumps(new_departures, indent=4)} \n")


# Widget Functionality Testing #

# directions = functionality.stopRoutes(stops)

departures3 = functionality.routeDepartures(new_departures)
