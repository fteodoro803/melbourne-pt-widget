import hashlib
import hmac
import requests

from enum import Enum


def getUrl(request):  # The request (make sure to format it as described in the documentation)
    # Request
    url_http = "http://timetableapi.ptv.vic.gov.au"
    url_https = "https://timetableapi.ptv.vic.gov.au"
    # make APIName an Enumerator of departrues, fares, search, etc

    # Signature
    developer_id = 3002772
    api_key = '22e5146f-b255-4ead-a64f-a21deb8acd2c'

    # Encode the api_key and message to bytes
    key_bytes = api_key.encode()
    signature_value = f"{request}?devid={developer_id}"
    message_bytes = signature_value.encode()

    # Generate HMAC SHA1 signature
    signature = hmac.new(key_bytes, message_bytes, hashlib.sha1).hexdigest().upper()

    # return f"{url_https}/{versionNumber}{request}?devid={developer_id}&signature={signature}"
    return f"{url_https}/{request}?devid={developer_id}&signature={signature}"


req1 = "/v3/route_types"

ptvRequest = req1
ptvUrl = getUrl(ptvRequest)
print(ptvUrl)

req = requests.get(ptvUrl)
print(req)
print(req.content)
