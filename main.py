import json

import requests
from queries import getURL, getRouteTypes, getStopsByLocation
from transport import getNearestStops

# # Get Route Types
# route_types = getRouteTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# Test Latitude and Longitude
latitude, longitude = -37.760666693450844, 144.94388904412543
stops = getStopsByLocation(latitude, longitude, route_types=[1], max_results=10)
print(f"Stops: \n{json.dumps(stops.json(), indent=2)} \n")

# # Test Getting Nearest Transport Options
# latitude, longitude = -37.7604291983108, 144.9436530097327
# nearest_ptv = getNearestStops(latitude, longitude)
# print(f"Nearest Options: \n{json.dumps(nearest_ptv.json(), indent=3)} \n")
