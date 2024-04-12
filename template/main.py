import ptv_api as ptv
import json


def main():
    print("===== PTV WIDGET TESTING =====\n")

    """ Showing Stops near Location """
    location = input("Enter your location (latitude, longitude): ")

    # Splitting the input string to Latitude and Longitude
    string_array = location.split(',')
    latitude, longitude = float(string_array[0]), float(string_array[1])

    stops_info = getStops(latitude, longitude)
    stop = input("Select stop id (int): ")

    """ Show Directions of a Route """
    route = input("Select route id (int): ")
    direction_info = getDirection(route)

    """ Show Departures for a Route at a Stop """
    direction = input("Select direction id (int): ")
    # departures =


# Get Stops and their respective Route Names and Numbers
def getStops(latitude, longitude):
    max_results, max_distance, route_types = 5, 300, [1]  # test values

    print(f"\n---Getting Stops---")

    print(f"latitude, longitude = {latitude}, {longitude}")
    print(f"Stops near your location:")

    stops = ptv.stops(latitude, longitude, max_results=max_results,
                      max_distance=max_distance, route_types=route_types)
    print(f"\nStops within {max_distance}m of ({latitude}, {longitude}): \n{json.dumps(stops.json(), indent=2)} \n")

    return stops


def getDirection(route):
    directions = ptv.routeDirections(route)
    print(f"\n---Getting Route Directions---")
    print(f"\nDirections of Route {route}: \n{json.dumps(directions.json(), indent=2)} \n")
    return directions


# def getDeparture(route_info, direction)


if __name__ == "__main__":
    main()
