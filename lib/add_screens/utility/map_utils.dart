import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../ptv_info_classes/stop_info.dart';


class GeoPathAndStops {
  final List<LatLng> geoPathWithStop;
  final LatLng? stopPositionAlongGeoPath;

  GeoPathAndStops(this.geoPathWithStop, this.stopPositionAlongGeoPath);
}

class PolyLineMarkers {
  final Set<Marker> largeMarkers;
  final Set<Marker> smallMarkers;

  final Marker? stopMarker;
  final Marker firstMarker;
  final Marker lastMarker;

  PolyLineMarkers(this.largeMarkers, this.smallMarkers, this.stopMarker, this.firstMarker, this.lastMarker);
}

class PolyLines {
  final Polyline futurePolyLine;
  final Polyline? previousPolyLine;

  PolyLines(this.futurePolyLine, this.previousPolyLine);
}

class MapUtils {

  double zoomThresholdLarge = 12.8; // Zoom level threshold to hide the marker
  double zoomThresholdSmall = 13.4;

  // Calculate polyline extent to adjust padding based on polyline size
  static double calculatePolylineExtent(List<LatLng> points) {
    LatLngBounds bounds = calculatePolylineBounds(points);

    // Calculate diagonal distance of the bounds as a rough measure of polyline size
    double latDiff = bounds.northeast.latitude - bounds.southwest.latitude;
    double lngDiff = bounds.northeast.longitude - bounds.southwest.longitude;

    // Use the Pythagorean theorem as a rough approximation
    return sqrt(latDiff * latDiff + lngDiff * lngDiff);
  }

  /// Helper method to calculate a position that will place our marker at the specified height ratio
  Future<LatLng> calculateOffsetPosition(LatLng center, double verticalFraction, GoogleMapController controller) async {
    // Get the current visible region
    LatLngBounds visibleRegion = await controller.getVisibleRegion();

    // Calculate the latitude span of the visible region
    double latSpan = visibleRegion.northeast.latitude - visibleRegion.southwest.latitude;

    // Calculate the offset needed to move the center to the desired vertical position
    // 0.5 is the center of the screen, so we calculate relative to that
    double latOffset = (0.5 - verticalFraction) * latSpan;

    // Return the new center position with the calculated offset
    return LatLng(center.latitude + latOffset, center.longitude);
  }

  /// Function to calculate the bounds that include all points within a given distance from _chosenPosition
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

  /// Retrieves address from coordinates of dropped pin
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

  /// Checks if polyline marker visibility should change
  bool didZoomChange(double oldZoom, double newZoom) {

    bool wasSmallHidden;
    bool wasLargeHidden;
    bool hideSmall;
    bool hideLarge;

    if (oldZoom < zoomThresholdSmall && oldZoom >= zoomThresholdLarge ) {
      wasSmallHidden = true;
      wasLargeHidden = false;
    }
    else if (oldZoom < zoomThresholdLarge ) {
      wasSmallHidden = true;
      wasLargeHidden = true;
    }
    else {
      wasSmallHidden = false;
      wasLargeHidden = false;
    }

    if (newZoom < zoomThresholdSmall && newZoom >= zoomThresholdLarge ) {
      hideSmall = true;
      hideLarge = false;
    }
    else if (newZoom < zoomThresholdLarge ) {
      hideSmall = true;
      hideLarge = true;
    }
    else {
      hideSmall = false;
      hideLarge = false;
    }

    return !(wasSmallHidden == hideSmall && wasLargeHidden == hideLarge);
  }

  // map_utils.dart
  Future<Marker> createNearbyStopMarker({
    required Stop stop,
    required BitmapDescriptor icon,
    required void Function() onTap,
  }) async {
    return Marker(
      markerId: MarkerId(stop.id.toString()),
      position: LatLng(stop.latitude!, stop.longitude!),
      icon: icon,
      consumeTapEvents: true,
      onTap: onTap,
    );
  }

  Future<Set<Marker>> generateNearbyStopMarkers({
    required List<Stop> stops,
    required Future<BitmapDescriptor> Function(Stop stop) getIcon,
    required void Function(Stop stop) onTapStop,
  }) async {
    final Set<Marker> markers = {};
    for (var stop in stops) {
      final icon = await getIcon(stop);
      final marker = await createNearbyStopMarker(
        stop: stop,
        icon: icon,
        onTap: () => onTapStop(stop),
      );
      markers.add(marker);
    }
    return markers;
  }

  Future<void> moveCameraToFitRadiusWithVerticalOffset({
    required GoogleMapController controller,
    required LatLng center,
    required double radiusInMeters,
    double verticalOffsetRatio = 0.65,
  }) async {
    // Step 1: Calculate bounds around the center point for the given radius
    LatLngBounds bounds = await calculateBoundsForMarkers(
      radiusInMeters,
      center,
    );

    // Step 2: Move camera to those bounds to determine the correct zoom
    await controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    await Future.delayed(Duration(milliseconds: 250));

    // Step 3: Get the calculated zoom level after the fit
    final zoom = await controller.getZoomLevel();

    // Step 4: Offset the center vertically to apply the desired marker height position
    final adjustedCenter = await calculateOffsetPosition(
      center,
      verticalOffsetRatio,
      controller,
    );

    // Step 5: Animate camera to final position with same zoom
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: adjustedCenter,
          zoom: zoom,
        ),
      ),
    );
  }

  // Helper method to calculate bounds that include all points in the polyline
  static LatLngBounds calculatePolylineBounds(List<LatLng> points) {
    double minLat = 90.0, maxLat = -90.0;
    double minLng = 180.0, maxLng = -180.0;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  static LatLng calculatePolylineCenter(List<LatLng> points) {
    double sumLat = 0.0, sumLng = 0.0;

    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(
      sumLat / points.length,
      sumLng / points.length,
    );
  }

  Future<void> centerMapOnPolyLine(List<LatLng> polyLine, GoogleMapController mapController, BuildContext context, bool enableSearch) async {
    LatLngBounds bounds = MapUtils.calculatePolylineBounds(polyLine);

    // Calculate padding based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate padding as percentage of screen dimensions
    // You can adjust these percentages based on your needs
    final horizontalPadding = enableSearch ? screenWidth * 0.35 : screenWidth * 0.25; // 15% of screen width
    final verticalPadding = enableSearch ? screenHeight * 0.35 : screenHeight * 0.25;  // 15% of screen height

    // Use the smaller value to ensure consistent padding
    final padding = horizontalPadding < verticalPadding ?
    horizontalPadding : verticalPadding;

    // Apply a minimum padding to ensure there's always some space
    final adaptivePadding = padding < 20 ? 20 : padding;

    // First animate to bounds to make sure all points are visible
    await mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, adaptivePadding.toDouble()),
    );

    // Wait for first animation to complete
    await Future.delayed(Duration(milliseconds: 300));

    // Get the current zoom level after fitting to bounds
    final zoom = await mapController.getZoomLevel();

    // Calculate the center point of the polyline
    LatLng center = MapUtils.calculatePolylineCenter(polyLine);

    // Calculate offset to position the center point at about 45% of screen height
    // (between your 0.3 and 0.6 target window)
    LatLng adjustedCenter = await calculateOffsetPosition(
        center,
        0.5, // Position in the middle of your 0.3-0.6 window
        mapController
    );

    // Animate to the new adjusted position
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: adjustedCenter,
          zoom: zoom,
        ),
      ),
    );
  }

  Future<BitmapDescriptor> getResizedImage(String assetPath, double width, double height) async {
    // Load the image from assets
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List();

    // Decode the image
    final ui.Image image = await decodeImageFromList(Uint8List.fromList(bytes));

    // Resize the image using a canvas
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(width, height)));
    final Paint paint = Paint();

    // Scale the image on the canvas
    canvas.drawImageRect(image, Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()), Rect.fromLTRB(0, 0, width, height), paint);

    // Convert to an image
    final ui.Image resizedImage = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());

    // Convert to byte data
    final ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    // Return the resized BitmapDescriptor
    return BitmapDescriptor.bytes(resizedBytes);
  }

  /// Returns set of markers with only location pin marker
  static Set<Marker> resetMarkers(LatLng? markerPosition) {

    Set<Marker> newMarkers = {};

    if (markerPosition != null) {
      MarkerId id = MarkerId(markerPosition.toString()); // Unique ID based on position

      newMarkers.add(Marker(
        markerId: id,
        position: markerPosition,
        consumeTapEvents: true,
      ));
    }

    return newMarkers;
  }
}

class GeoPathUtils {

  /// Helper function to find the point in a geoPath that is closest to a given point
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

  /// Helper function to find the projected position of a point directly on the geoPath
  static LatLng generatePointOnGeoPath(LatLng center, List<LatLng> path) {
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

  /// Helper function to calculate the distance between two points
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

  /// Helper function to determine whether a the transport path and markers should be reversed
  static bool reverseDirection(List<LatLng> geopath, List<LatLng> stopPositions) {
    LatLng firstGeoPathPoint = geopath[0];
    LatLng lastGeoPathPoint = geopath[geopath.length - 1];
    LatLng lastStopLocation = stopPositions[stopPositions.length - 1];
    return calculateDistance(lastStopLocation, firstGeoPathPoint)
        < calculateDistance(lastStopLocation, lastGeoPathPoint);
  }
}