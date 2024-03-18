# from features import getURL
import configparser

""" Config """
# Reads config.ini


def readConfig():
    config = configparser.ConfigParser()
    config.read('../config.ini')
    return config


# Checks if User_ID field is not empty
def testUserIDNotEmpty():
    config = readConfig()
    user_id = config['DEFAULT']['USER_ID']
    # print(f"USER_ID: '{user_id}'")  # Debug print
    assert user_id, "USER_ID should not be empty"


# Checks if API_KEY field is not empty
def testAPIKeyNotEmpty():
    config = readConfig()
    api_key = config['DEFAULT']['API_KEY']
    # print(f"API_KEY: '{api_key}'")  # Debug print
    assert api_key, "API_KEY should not be empty"

""" getURL """
# Valid Requests
# Invalid Requests