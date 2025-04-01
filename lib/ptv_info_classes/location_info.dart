import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_info.g.dart';

/// Represents a location of a stop.
/// Handles parsing of coordinates and conversion between GoogleMaps' LatLng.
@JsonSerializable()
class Location {
  String coordinates;   // string representation in "latitude, longitude" format
  String? name;
  double latitude;      // parsed latitude as a double
  double longitude;     // parsed longitude as a double

  /// Creates a Location from a coordinate string.
  /// Automatically parses the string to extract latitude and longitude.
  Location({required this.coordinates, this.name})
      : latitude = 0,
        longitude = 0 {
    _parseCoordinates(coordinates);
  }

  /// Creates a Location from a GoogleMaps LatLng.
  /// Also creates a string representation of coordinates.
  Location.withLatLng(LatLng location, {this.name})
      : latitude = location.latitude,
        longitude = location.longitude,
        coordinates = "${location.latitude}, ${location.longitude}";

  /// Parses a coordinate string into latitude and longitude values.
  void _parseCoordinates(String coordinates) {
    // Check if empty
    if (coordinates.isEmpty) {
      throw FormatException("Empty coordinates");
    }

    // Split the location string by comma ("latitude,longitude" format)
    List<String> parts = coordinates.split(',');

    // Ensure there is only Latitude and Longitude
    if (parts.length != 2) {
      throw FormatException(
          "Invalid location format. Expected \"latitude,longitude\"");
    }

    try {
      latitude = double.parse(parts[0].trim()); // Parse latitude from string
      longitude = double.parse(parts[1].trim()); // Parse longitude from string
    } catch (e) {
      // Case where parsing fails
      throw FormatException(
          "Invalid location format. Latitude and Longitude must be numeric");
    }
  }

  /// Converts this location to a GoogleMaps LatLng object.
  /// Useful for map operations and markers.
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  @override
  String toString() {
    return "Location: $coordinates, Name: $name\n"
        "\tLatitude, Longitude: $latitude, $longitude\n";
  }

  /// Methods for JSON Serialization.
  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
