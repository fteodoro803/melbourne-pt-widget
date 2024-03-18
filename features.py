# URL Generation
import hashlib          # for signature generation
import hmac             # for signature generation
import configparser     # for getting userID/devID and API Key from config
from urllib.parse import urlencode, unquote      # for URL modifications

# Data Gathering
import requests         # for getting data from PTV API


# Gets Request URL
def getURL(request: str, parameters: list[tuple[str, str]] = None) -> str:
    if parameters is None:
        parameters = []

    # Base URL
    url_http = "http://timetableapi.ptv.vic.gov.au"
    url_https = "https://timetableapi.ptv.vic.gov.au"

    # Signature
    config = configparser.ConfigParser()
    config.read('config.ini')
    developer_id = config['DEFAULT']['USER_ID']
    parameters.append(('devid', developer_id))
    api_key = config['DEFAULT']['API_KEY']

    # Encode the api_key and message to bytes
    key_bytes = api_key.encode()
    signature_value_parameters = urlencode(parameters)
    signature_value = f"{request}?{signature_value_parameters}"     # "The signature value is a HMAC-SHA1 hash of the completed request (minus the base URL but including your user ID, known as “devid”) and the API key"
    print(signature_value)
    message_bytes = signature_value.encode()

    # Generate HMAC SHA1 signature
    signature = hmac.new(key_bytes, message_bytes, hashlib.sha1).hexdigest().upper()
    parameters.append(('signature', signature))

    # URL
    encoded_parameters = urlencode(parameters)  # adds parameters to url
    url = f"{url_https}/{request}?{encoded_parameters}"
    print(f"Url: {url}")    # ~test
    return url


# Gets Nearest form of PTV
def getNearestTransport(latitude: float, longitude: float, route_types: list[int] = None, max_results=None, max_distance=None):
    parameters = []

    if route_types is not None:
        route_tuples = [('route_types', typeInt) for typeInt in route_types]
        parameters += route_tuples

    if max_results is not None:
        parameters += [('max_results', max_results)]

    if max_distance is not None:
        parameters += [('max_distance', max_distance)]

    # if route_types is not None:
    #     # conversion to tuples
    #     route_tuples = [('route_types', typeInt) for typeInt in route_types]
    #     url = getURL(f"/v3/stops/location/{latitude},{longitude}", route_tuples)

    if len(parameters) >= 1:
        url = getURL(f"/v3/stops/location/{latitude},{longitude}", parameters)
    else:
        url = getURL(f"/v3/stops/location/{latitude},{longitude}")

    request = requests.get(url)
    return request


# Gets the Route Types available by PTV
def getRouteTypes():
    url = getURL(f"/v3/route_types")
    request = requests.get(url)
    return request

