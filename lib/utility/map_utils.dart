import 'dart:math';

import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUtils {
  // Helper method to calculate a position that will place our marker at the specified height ratio
  Future<LatLng> calculateOffsetPosition(LatLng markerPosition, double heightRatio, GoogleMapController controller) async {
    // Get the visible region to determine map dimensions
    LatLngBounds visibleRegion = await controller.getVisibleRegion();

    // Calculate the total span of visible latitude
    double latSpan = visibleRegion.northeast.latitude - visibleRegion.southwest.latitude;

    // Calculate offset needed to position marker at heightRatio (0.7) of screen height
    // For 0.7 (70% from top), we need to move the center up by (0.5 - (1-0.7)) = 0.2 of the screen
    double latOffset = latSpan * (0.5 - (1 - heightRatio));

    // Create new position with the same longitude but adjusted latitude
    return LatLng(
      markerPosition.latitude + latOffset,
      markerPosition.longitude,
    );
  }

  // Function to calculate the bounds that include all points within a given distance from _chosenPosition
  Future<LatLngBounds> calculateBoundsForMarkers(double distanceInMeters, LatLng markerPosition) async {
    List<LatLng> allPoints = [];
    LatLng chosenPosition = markerPosition;

    // Add the chosen position as the center point
    allPoints.add(chosenPosition);

    double latMin = chosenPosition.latitude;
    double latMax = chosenPosition.latitude;
    double lonMin = chosenPosition.longitude;
    double lonMax = chosenPosition.longitude;

    for (LatLng point in allPoints) {
      double latDelta = point.latitude - chosenPosition.latitude;
      double lonDelta = point.longitude - chosenPosition.longitude;

      if (latDelta < latMin) latMin = point.latitude;
      if (latDelta > latMax) latMax = point.latitude;

      if (lonDelta < lonMin) lonMin = point.longitude;
      if (lonDelta > lonMax) lonMax = point.longitude;
    }

    // Adjusting bounds to cover the given distance
    double latDistance = distanceInMeters / 111000; // 111000 meters = 1 degree of latitude
    double lonDistance = distanceInMeters / (111000 * cos(chosenPosition.latitude * pi / 180));

    latMin -= latDistance;
    latMax += latDistance;
    lonMin -= lonDistance;
    lonMax += lonDistance;

    // Return the calculated bounds
    return LatLngBounds(
      southwest: LatLng(latMin, lonMin),
      northeast: LatLng(latMax, lonMax),
    );
  }

  // Retrieves address from coordinates of dropped pin
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
      await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        // Return a string with the address (you can adjust what part of the address you want)
        return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Address not found"; // Return a default message if something goes wrong
  }
}