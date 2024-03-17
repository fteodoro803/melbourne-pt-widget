import requests
from features import getURL


test_request_1 = "/v3/route_types"

ptv_Request = test_request_1
ptv_URL = getURL(ptv_Request)
print(ptv_URL)

req = requests.get(ptv_URL)
print(req)
print(req.json())
