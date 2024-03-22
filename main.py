from datetime import datetime, timezone
import json

import requests
from queries import getURL, getRouteTypes, getStopsByLocation, getRouteDirections, getDepartures
from transport import getNearestStops

# Test Variables
# Current: Anstey Station
stop_id = 1006
route_id = 15
route_type = 0
latitude, longitude = -37.760840935413775, 144.9438046259414
currDate = "2024-03-20"
current_date = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
current_date_iso = current_date.isoformat()


# # Get Route Types
# route_types = getRouteTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# # Test Latitude and Longitude
# stops = getStopsByLocation(latitude, longitude, route_types=[0], max_results=10, max_distance=1800)
# print(f"Stops: \n{json.dumps(stops.json(), indent=2)} \n")

# # Test Getting Nearest Transport Options
# nearest_ptv = getNearestStops(latitude, longitude)
# print(f"Nearest Options: \n{json.dumps(nearest_ptv.json(), indent=3)} \n")

# # Test Getting Route Directions
# print(f"Directions for Route {route}: \n{json.dumps(getRouteDirections(route).json(), indent=2)} \n")


# Test Departures
expands = None
departures = getDepartures(route_type, stop_id, route_id, expand=expands, date_utc=currDate)
print(f"Departures for stopID {stop_id}, routeType {route_type}: \n{json.dumps(departures.json(), indent=2)} \n")

