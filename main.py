from datetime import datetime, timezone
import json

import requests
from api import getURL, getRouteTypes, getStopsByLocation, getRouteDirections, getDepartures
from transport import getNearestStops
from utilities import convertUTCtoLocalTime, convertDepartureTimesToLocalTime

# Test Variables
# # Anstey Station
# stop_id = 1006
# route_id = 15
# route_type = 0
# latitude, longitude = -37.760840935413775, 144.9438046259414
# currDate = "2024-03-20"
# current_date = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
# current_date_iso = current_date.isoformat()


# # 58 Tram on by Red Rooster Coburg
# latitude, longitude = -37.75293501480111, 144.94549837144285
# route_types = [1]
# max_results = 3
# max_distance = 300
# route_id = 11529
# route_gtfs_id = "3-058"
# stop_id = 3081
# route_type = 1

# Hope St
latitude, longitude = -37.761839285786365, 144.94352487683278
route_id = 11529
stop_id = 3086
route_type = 1


# # Get Route Types
# route_types = getRouteTypes()
# print(f"Route Types: \n{route_types.json()} \n")

# # Test Latitude and Longitude
# stops = getStopsByLocation(latitude, longitude, route_types=route_types, max_results=max_results, max_distance=max_distance)
# print(f"Stops: \n{json.dumps(stops.json(), indent=2)} \n")

# # Test Getting Nearest Transport Options
# nearest_ptv = getNearestStops(latitude, longitude)
# print(f"Nearest Options: \n{json.dumps(nearest_ptv.json(), indent=3)} \n")

# # Test Getting Route Directions
# print(f"Directions for Route {route_id}: \n{json.dumps(getRouteDirections(route_id).json(), indent=2)} \n")


# Test Departures
expands = None
departures = getDepartures(route_type, stop_id, route_id, max_results=5)    # JSON File
new_departures = convertDepartureTimesToLocalTime(departures.json())
print(f"Departures for stopID {stop_id}, routeType {route_type}: \n{json.dumps(new_departures, indent=4)} \n")


