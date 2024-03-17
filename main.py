import requests
from features import getURL, getRouteTypes, getNearestTransport

# # Get Route Types
# route_types = getRouteTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# Test Latitude and Longitude
latitude, longitude = -37.75867404716728, 144.96349798490675
nearest_tram = getNearestTransport(latitude, longitude, route_types=[1])
print(f"Nearest Tram: \n{nearest_tram.json()} \n")


