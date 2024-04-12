from requests import Response
import ptv_api as ptv
from typing import Dict, Any            # for typehints (JSON)


# Get all Routes from a Stop --> convert input from Response to JSON
def stopRoutes(stop_data: Response) -> dict:
    directions_dict = {}

    # Converting Response to JSON Data
    data = stop_data.json()

    for stop in data["stops"]:
        for route in stop["routes"]:
            route_number = route["route_number"]
            route_name = route["route_name"]

            directions_dict[route_number] = route_name

    print(f"directions_dict: {directions_dict}")
    return directions_dict


# Get next 3 Departures for each Route
def routeDepartures(departure_data: dict[str, Any]) -> dict:
    departures_dict = {}

    # Initialising each Route into Departures
    for route in departure_data["routes"]:
        route = int(route)      # ensure key is an integer

        directions = departure_data["directions"]
        for direction in directions:
            route_id = int(directions[direction]["route_id"])
            if route_id == route:
                direction = int(direction)
                departures_dict[(route, direction)] = []

    # Adding departures for each Route and Direction
    for departure in departure_data["departures"]:
        route_id = int(departure["route_id"])
        direction_id = int(departure["direction_id"])
        next_departure = departure["scheduled_departure"]

        for key in departures_dict:
            # print(f"key={key} || route_id={route_id}, direction_id={direction_id}")
            if key[0] == route_id and key[1] == direction_id:
                departures_dict[(route_id, direction_id)].append(next_departure)

    print(f"departures_dict: {departures_dict}")
    print(f"readable departures_dict: {departuresHumanReadable(departures_dict, departure_data)}")

    return departures_dict


def departuresHumanReadable(dictionary: [(int, int), Any], departure_data: [str, Any]) -> [(str, str), Any]:
    newDict = {}
    routes = departure_data["routes"]
    directions = departure_data["directions"]

    for (route, direction) in dictionary:
        scheduled_departure = dictionary[(route, direction)]
        route_name = routes[str(route)]["route_name"]
        direction_name = directions[str(direction)]["direction_name"]
        # print(f"route_name: {route_name}, direction_name: {direction_name}")
        newDict[(route_name, direction_name)] = scheduled_departure

    return newDict
