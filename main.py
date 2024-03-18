import json

import requests
from queries import getURL, getRouteTypes, getNearestTransport

# # Get Route Types
# route_types = getRouteTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# Test Latitude and Longitude
latitude, longitude = -37.779529900176406, 144.93050385805827
nearest_tram = getNearestTransport(latitude, longitude, route_types=[1], max_results=10)
print(f"Nearest Tram: \n{json.dumps(nearest_tram.json(), indent=2)} \n")


