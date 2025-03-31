import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_info.g.dart';

@JsonSerializable()
class Location {
  String coordinates;
  String? name;
  double latitude;
  double longitude;

  Location({required this.coordinates, this.name}) : latitude = 0, longitude = 0 {
    _parseCoordinates(coordinates);
  }

  Location.withLatLng(LatLng location, {this.name}) :
        latitude = location.latitude,
        longitude = location.longitude,
        coordinates = "${location.latitude}, ${location.longitude}";

  void _parseCoordinates(String coordinates) {
    // Check if empty
    if (coordinates.isEmpty) {
      throw FormatException("Empty coordinates");
    }

    // Split the location string by comma ("latitude,longitude" format)
    List<String> parts = coordinates.split(',');

    // Ensure there is only Latitude and Longitude
    if (parts.length != 2) {
      throw FormatException("Invalid location format. Expected \"latitude,longitude\"");
    }

   try {
      latitude = double.parse(parts[0].trim()); // Parse latitude from string
      longitude = double.parse(parts[1].trim()); // Parse longitude from string
    } catch (e) {
      // Case where parsing fails
      throw FormatException("Invalid location format. Latitude and Longitude must be numeric");
    }
  }

  @override
  String toString() {
    return "Location: $coordinates, Name: $name\n"
        "\tLatitude, Longitude: $latitude, $longitude\n";
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  // Methods for JSON Serialization
  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}