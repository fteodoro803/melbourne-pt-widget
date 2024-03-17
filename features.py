import hashlib
import hmac
import configparser

# Gets Request URL
def getURL(request):
    # Request
    url_http = "http://timetableapi.ptv.vic.gov.au"
    url_https = "https://timetableapi.ptv.vic.gov.au"

    # Signature
    config = configparser.ConfigParser()
    config.read('config.ini')
    developer_id = config['DEFAULT']['USER_ID']
    api_key = config['DEFAULT']['API_KEY']

    # Encode the api_key and message to bytes
    key_bytes = api_key.encode()
    signature_value = f"{request}?devid={developer_id}"
    message_bytes = signature_value.encode()

    # Generate HMAC SHA1 signature
    signature = hmac.new(key_bytes, message_bytes, hashlib.sha1).hexdigest().upper()

    # return f"{url_https}/{versionNumber}{request}?devid={developer_id}&signature={signature}"
    return f"{url_https}/{request}?devid={developer_id}&signature={signature}"
