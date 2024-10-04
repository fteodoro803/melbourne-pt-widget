class Selections {      // consider changing these to the Info classes
  // route
  String? routeType;   // public transport type (tram, train, bus, etc)
  String? routeTypeName;  // for readability
  String? routeId;
  String? routeName;
  String? routeNumber;


  // location
  String? selectedLocation;

  // stop
  String? stopId;
  String? stopName;
  String? stopSuburb;
  String? stopLatitude;
  String? stopLongitude;

  @override
  String toString() {
    return "Route Type: $routeType - $routeTypeName \n"
        "Selected Location: $selectedLocation";
  }
}