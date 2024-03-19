from queries import getStopsByLocation
from requests import Response


def getNearestStops(latitude: float, longitude: float):       # nearest Unique PTV options by Type
    return getStopsByLocation(latitude, longitude)
