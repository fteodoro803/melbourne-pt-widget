import json
from datetime import datetime           # for manipulating datetime
from zoneinfo import ZoneInfo           # for converting between timezones
from typing import Dict, Any            # for typehints (JSON)


# Convert a UTC Time to local (Melbourne) Time
def convertUTCtoLocalTime(utc_time: str) -> str | None:
    """
    Convert a UTC Time String to a Local Time String formatted for Melbourne, Australia.

    Parameters:
    - utc_time (str): UTC time string in the format "%Y-%m-%dT%H:%M:%SZ".

    Returns:
    - str: Local time string for Melbourne in the format "%Y-%m-%d %H:%M:%S %Z%z".
    """

    if utc_time:
        # Convert UTC Time String to Datetime object
        datetime_object_utc = datetime.strptime(utc_time, "%Y-%m-%dT%H:%M:%SZ")     # parsing string to datetime object
        datetime_object_utc = datetime_object_utc.replace(tzinfo=ZoneInfo("UTC"))           # making it timezone aware

        # Conversion to Melbourne timezone (automatically calculates daylight savings)
        local_time = datetime_object_utc.astimezone(ZoneInfo("Australia/Melbourne"))
        local_time_string = local_time.strftime("%Y-%m-%d %H:%M:%S %Z%z")

        return local_time_string

    else:
        return None


# Convert scheduled/estimated_departure_utc times in Departures JSON File to Local Time
def convertDepartureTimesToLocalTime(departures: Dict[str, Any]) -> Dict[str, Any]:
    """
    Adds the converted scheduled and estimated UTC departure times in a JSON file.

    Parameters:
    - departures (Dict[str, Any]): A JSON file returned by calling the PTV's departure API.

    Returns:
    - Dict[str, Any]: A JSON file including the converted departure times. Aside from the conversions, it is identical
        to the input JSON file
    """

    print(departures)      #~test
    # updated_departures = departures

    # Convert UTC Departure Times to Local Time
    for departure in departures['departures']:
        # scheduled departure time
        scheduled_departure_utc = departure['scheduled_departure_utc']
        scheduled_departure = convertUTCtoLocalTime(scheduled_departure_utc)
        departure['scheduled_departure'] = scheduled_departure

        # estimated departure time
        estimated_departure_utc = departure['estimated_departure_utc']
        estimated_departure = convertUTCtoLocalTime(estimated_departure_utc)
        departure['estimated_departure'] = estimated_departure

    # print(json.dumps(updated_departures, indent=4))        #~test

    return departures
