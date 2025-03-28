// idk if the app needs to store this? maybe at most get the users current location to get nearest stops, but delete after~

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_info.g.dart';

@JsonSerializable()
class Location {
  String? name;
  String coordinates;
  double latitude;
  double longitude;

  Location({required this.coordinates, this.name}) : latitude = 0, longitude = 0 {
    // Split the location string by comma (assuming "latitude,longitude" format)
    List<String> parts = coordinates.split(',');

    // Ensure there are exactly two parts (latitude and longitude)
    if (parts.length == 2) {
      latitude = double.parse(parts[0].trim()); // Parse latitude from string
      longitude = double.parse(parts[1].trim()); // Parse longitude from string
    } else {
      latitude = 0;
      longitude = 0;
      throw FormatException(
          '( location_info.dart -> constructor ) -- Invalid location format');
    }
  }

  Location.withLatLng(LatLng location, {this.name}) :
    latitude = location.latitude,
    longitude = location.longitude,
    coordinates = "${location.latitude},${location.longitude}";


  @override
  String toString() {
    return "Location: $coordinates\t Name: $name\n"
        "\tLatitude, Longitude = $latitude, $longitude\n";
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  // Methods for JSON Serialization
  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}