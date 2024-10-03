class Selections {
  int? routeType;   // public transport type (tram, train, bus, etc)
  String? routeTypeName;  // for readability

  // location
  double? latitude;
  double? longitude;

  @override
  String toString() {
    return "Selections: \n"
        "Route Type: $routeType - $routeTypeName \n"
        "Location: $latitude, $longitude";
  }
}