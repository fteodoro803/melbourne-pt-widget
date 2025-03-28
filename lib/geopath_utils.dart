import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeoPathUtils {
  static LatLng findClosestPointOnLine(LatLng center, LatLng p1, LatLng p2) {
    // Calculate the vector from p1 to p2
    double dx = p2.longitude - p1.longitude;
    double dy = p2.latitude - p1.latitude;

    // Calculate the vector from p1 to center
    double t = ((center.longitude - p1.longitude) * dx + (center.latitude - p1.latitude) * dy) /
        (dx * dx + dy * dy);

    // Clip t to be between 0 and 1 to ensure it falls within the line segment
    t = t < 0 ? 0 : (t > 1 ? 1 : t);

    // Calculate the closest point on the line
    double closestLongitude = p1.longitude + t * dx;
    double closestLatitude = p1.latitude + t * dy;

    return LatLng(closestLatitude, closestLongitude);
  }

  static LatLng findClosestPoint(LatLng center, List<LatLng> path) {
    double minDistance = double.infinity;
    LatLng closestPoint = path[0];

    for (int i = 0; i < path.length - 1; i++) {
      // Get the closest point on the line segment between path[i] and path[i + 1]
      LatLng projectedPoint = findClosestPointOnLine(center, path[i], path[i + 1]);

      // Calculate the distance from the center to the projected point
      double distance = calculateDistance(center, projectedPoint);

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = projectedPoint;
      }
    }

    return closestPoint;
  }

  static double calculateDistance(LatLng point1, LatLng point2) {
    // Use the Haversine formula or a simpler Euclidean distance calculation
    var lat1 = point1.latitude;
    var lng1 = point1.longitude;
    var lat2 = point2.latitude;
    var lng2 = point2.longitude;

    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos(lat1 * p) * cos(lat2 * p) * cos((lng2 - lng1) * p) +
        sin(lat1 * p) * sin(lat2 * p);
    var distance = 6371 * acos(c); // Distance in km
    return distance;
  }

  static bool isBetween(LatLng point, LatLng pointA, LatLng pointB) {
    // Simple distance-based check or use a geometry-based approach for precision
    double distanceAB = calculateDistance(pointA, pointB);
    double distanceAClosest = calculateDistance(pointA, point);
    double distanceBClosest = calculateDistance(pointB, point);

    // If the sum of distances from point to pointA and pointB equals the distance from pointA to pointB
    return (distanceAClosest + distanceBClosest - distanceAB).abs() < 0.001;
  }

}