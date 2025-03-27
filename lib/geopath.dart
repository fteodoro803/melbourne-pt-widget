import 'package:flutter_project/file_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void convertPolylineToCsv(List<dynamic> paths) {
  // Ensure we're working with the first path (assuming single path)
  String polyline = paths.first.toString();

  // Split the polyline into individual coordinate pairs
  List<String> coordinatePairs = polyline.trim().split('-');
  print("(geopath.dart -> convertPolyLineToCSV) -- coordinate pairs: ${coordinatePairs.length}");

  // Create CSV buffer
  StringBuffer csvBuffer = StringBuffer();

  // Write header
  csvBuffer.writeln('latitude,longitude');

  // Parse and write each coordinate pair
  for (var coord in coordinatePairs) {
    // Split each coordinate pair and trim whitespace
    List<String> latLon = coord.trim().split(',');

    // Write to CSV
    if (latLon.length > 1){
      csvBuffer.writeln('-${latLon[0].trim()},${latLon[1].trim()}');
    }
  }

  String str = csvBuffer.toString();

  saveGeoPath(str);
}

List<LatLng> convertPolylineToLatLng(List<dynamic> paths) {
  // Ensure we're working with the first path (assuming single path)
  String polyline = paths.first.toString();

  // Split the polyline into individual coordinate pairs
  List<String> coordinatePairs = polyline.trim().split('-');

  // Parse coordinates
  List<LatLng> coordinates = [];
  for (var coord in coordinatePairs) {
    // Split each coordinate pair and trim whitespace
    List<String> latLon = coord.trim().split(',');

    // Ensure we have both latitude and longitude
    if (latLon.length > 1) {
      String latitude = "-${latLon[0].trim()}";   // replace the removed negative sign
      String longitude = latLon[1].trim();
      LatLng newCoordinates = LatLng(double.parse(latitude), double.parse(longitude));
      coordinates.add(newCoordinates);
    }
  }

  return coordinates;
}