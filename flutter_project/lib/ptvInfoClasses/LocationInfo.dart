// idk if the app needs to store this? maybe at most get the users current location to get nearest stops, but delete after

class Location {
  String location;
  // latitude and longitude?

  Location({required this.location});

  @override
  String toString() {
    return "Location: $location";
  }
}