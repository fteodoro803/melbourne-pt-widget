# PTV API Calls/Requests

# URL Generation
import hashlib          # for signature generation
import hmac             # for signature generation
import configparser     # for getting userID/devID and API Key from config
import os               # for locating config
from urllib.parse import urlencode, unquote      # for URL modifications

# Data Gathering
import requests         # for getting data from PTV API
from requests import Response
from datetime import datetime


# Gets Request URL
def getURL(request: str, parameters: list[tuple[str, str]] = None) -> str:
    if parameters is None:
        parameters = []

    # Base URL
    url_http = "http://timetableapi.ptv.vic.gov.au"
    url_https = "https://timetableapi.ptv.vic.gov.au"

    # Signature
    # config = configparser.ConfigParser()
    # config_path = os.path.join(os.path.dirname(__file__), 'config.ini')
    # # config.read('config.ini')
    # config.read(config_path)
    config = loadConfig()
    developer_id = config['DEFAULT']['USER_ID']
    parameters.append(('devid', developer_id))
    api_key = config['DEFAULT']['API_KEY']

    # Encode the api_key and message to bytes
    key_bytes = api_key.encode()
    signature_value_parameters = urlencode(parameters)
    signature_value = f"{request}?{signature_value_parameters}"     # "The signature value is a HMAC-SHA1 hash of the completed request (minus the base URL but including your user ID, known as “devid”) and the API key"
    print(signature_value)      #~test
    message_bytes = signature_value.encode()

    # Generate HMAC SHA1 signature
    signature = hmac.new(key_bytes, message_bytes, hashlib.sha1).hexdigest().upper()
    parameters.append(('signature', signature))

    # URL
    encoded_parameters = urlencode(parameters)  # adds parameters to url
    url = f"{url_https}/{request}?{encoded_parameters}"
    print(f"Url: {url}")    # ~test
    return url


# Loading Config
def loadConfig():
    # # Get the directory of the current script
    # dir_path = os.path.dirname(os.path.realpath(__file__))
    # # Go up one level to the parent directory where config.ini resides
    # parent_dir_path = os.path.join(dir_path, '..')
    # # Create the full path to the config.ini file
    # config_path = os.path.join(parent_dir_path, 'config.ini')
    #
    # config = configparser.ConfigParser()
    # config.read(config_path)

    dir_path = os.path.dirname(os.path.realpath(__file__))
    config_path = os.path.join(dir_path, 'config.ini')

    config = configparser.ConfigParser()
    config.read(config_path)

    return config


# Gets stops by Location (Latitude, Longitude)
def stops(latitude: float, longitude: float, route_types: list[int] = None,
          max_results: int = None, max_distance: int = None) -> Response:

    # Adding parameters
    parameters = []

    if route_types is not None:
        route_tuples = [('route_types', typeInt) for typeInt in route_types]
        parameters += route_tuples

    if max_results is not None:
        parameters += [('max_results', max_results)]

    if max_distance is not None:
        parameters += [('max_distance', max_distance)]

    # PTV API request
    if len(parameters) >= 1:
        url = getURL(f"/v3/stops/location/{latitude},{longitude}", parameters)
    else:
        url = getURL(f"/v3/stops/location/{latitude},{longitude}")

    response = requests.get(url)
    return response


# Gets the Route Types available by PTV
def routeTypes() -> Response:
    url = getURL(f"/v3/route_types")
    response = requests.get(url)
    return response


# Gets Route direction
def routeDirections(route_id: int) -> Response:
    url = getURL(f"/v3/directions/route/{route_id}")
    response = requests.get(url)
    return response


# Departures from Stop
def departures(route_type: int, stop_id: int, route_id: int = None, direction_id: int = None, date_utc: datetime = None, max_results: int = None, expand: list[str] = None) -> Response:

    parameters = []

    # Direction
    if direction_id:
        parameters += [('direction_id', direction_id)]

    # Date
    if date_utc:
        parameters += [('date_utc', date_utc)]

    # Max Results
    if max_results:
        parameters += [('max_results', max_results)]

    # Expands
    if expand:
        expand_tuples = [('expand', expandStr) for expandStr in expand]
        parameters += expand_tuples

    # PTV API request
    if route_id:        # If route ID is provided
        if len(parameters) >= 1:
            url = getURL(f"/v3/departures/route_type/{route_type}/stop/{stop_id}/route/{route_id}", parameters)
        else:
            url = getURL(f"/v3/departures/route_type/{route_type}/stop/{stop_id}/route/{route_id}")
    else:
        if len(parameters) >= 1:
            url = getURL(f"/v3/departures/route_type/{route_type}/stop/{stop_id}", parameters)
        else:
            url = getURL(f"/v3/departures/route_type/{route_type}/stop/{stop_id}")

    response = requests.get(url)
    return response
