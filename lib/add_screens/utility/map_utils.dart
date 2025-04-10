import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/services.dart';
import 'time_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class GeoPathAndStops {
  final List<LatLng> geoPathWithStops;
  final List<LatLng> stopsAlongGeoPath;
  final LatLng? stopPositionAlongGeoPath;

  GeoPathAndStops(this.geoPathWithStops, this.stopsAlongGeoPath, this.stopPositionAlongGeoPath);
}

class PolyLineMarkers {
  final Set<Marker> largeMarkers;
  final Set<Marker> smallMarkers;

  final Marker? stopMarker;
  final Marker firstMarker;
  final Marker lastMarker;

  PolyLineMarkers(this.largeMarkers, this.smallMarkers, this.stopMarker, this.firstMarker, this.lastMarker);
}

class MapUtils {

  double zoomThresholdLarge = 12.8; // Zoom level threshold to hide the marker
  double zoomThresholdSmall = 13.4;

  /// Helper method to calculate a position that will place our marker at the specified height ratio
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

  /// Changes polyline marker visibility on zoom change
  Set<Marker> onZoomChange(Set<Marker> markers, double zoom, PolyLineMarkers polyLineMarkers, LatLng markerPosition) {

    Set<Marker> newMarkers = {};

    if (zoom < zoomThresholdLarge) {

      newMarkers = TransportPathUtils.resetMarkers(markerPosition);
      if (polyLineMarkers.stopMarker != null) {
        newMarkers.add(polyLineMarkers.stopMarker!);
      }
      newMarkers.add(polyLineMarkers.firstMarker);
      newMarkers.add(polyLineMarkers.lastMarker);

    } else if (zoom < zoomThresholdSmall && zoom >= zoomThresholdLarge) {
      newMarkers = TransportPathUtils.resetMarkers(markerPosition);
      if (polyLineMarkers.stopMarker != null) {
        newMarkers.add(polyLineMarkers.stopMarker!);
      }
      newMarkers.add(polyLineMarkers.firstMarker);
      newMarkers.add(polyLineMarkers.lastMarker);
      newMarkers = {...newMarkers, ...polyLineMarkers.largeMarkers};
    }
    else {
      // Re-add the marker when zoom is above the threshold
      newMarkers = {...markers, ...polyLineMarkers.smallMarkers, ...polyLineMarkers.largeMarkers};
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


class TransportPathUtils {
  /// Returns set of markers with only location pin marker
  static Set<Marker> resetMarkers(LatLng markerPosition) {
    Set<Marker> newMarkers = {};

    MarkerId id = MarkerId(markerPosition.toString()); // Unique ID based on position

    newMarkers.add(Marker(
      markerId: id,
      position: markerPosition,
      consumeTapEvents: true,
    ));
    return newMarkers;
  }

  Future<Set<Polyline>> loadRoutePolyline(String routeColour, List<LatLng> geoPath, bool isDirectionSpecified, bool isReverseDirection, {LatLng? stopPositionAlongGeoPath}) async {

    Set<Polyline> polyLines = {};
    geoPath = isReverseDirection ? geoPath.reversed.toList() : geoPath;
    List<LatLng> previousRoute = [];
    List<LatLng> futureRoute = List.from(geoPath);
    int? closestIndex;

    if (stopPositionAlongGeoPath != null) {
      closestIndex = geoPath.indexOf(stopPositionAlongGeoPath);

      // Separate the coordinates into previous and future journey
      previousRoute = geoPath.sublist(0, closestIndex + 1);
      futureRoute = isDirectionSpecified ? geoPath.sublist(closestIndex) : geoPath;
    }

    if (isDirectionSpecified) {
      // Add polyline for previous journey
      polyLines.add(Polyline(
        polylineId: PolylineId('previous_route_polyline'),
        color: Color(0xFFB6B6B6),
        width: 6,
        points: previousRoute,
      ));
    }

    // Add polyline for future journey
    polyLines.add(Polyline(
      polylineId: PolylineId('future_route_polyline'),
      color: ColourUtils.hexToColour(routeColour),
      width: 9,
      points: futureRoute,
    ));

    return polyLines;

  }

  Future<PolyLineMarkers> setMarkers(
      Set<Marker> markers,
      List<LatLng> stopPositions,
      bool isDirectionSpecified,
      {
        LatLng? stopPosition,
        LatLng? stopPositionAlongGeoPath,
      }
      ) async {

    Set<Marker> largeMarkers = {};
    Set<Marker> smallMarkers = {};
    Marker? stopMarker;
    Marker firstMarker;
    Marker lastMarker;

    LatLng? chosenStopPosition = isDirectionSpecified ? stopPosition : stopPositionAlongGeoPath;

    BitmapDescriptor? customMarkerIconFuture = await getResizedImage("assets/icons/Marker Filled.png", 9, 9);
    BitmapDescriptor? customMarkerIconPrevious = await getResizedImage("assets/icons/Marker Filled.png", 7, 7);

    BitmapDescriptor? customMarkerIcon = isDirectionSpecified
        ? customMarkerIconPrevious
        : customMarkerIconFuture;
    BitmapDescriptor? customStopMarkerIcon = await getResizedImage("assets/icons/Marker Filled.png", 20, 20);

    bool isLargeMarker = isDirectionSpecified ? false : true;

    for (var stop in stopPositions) {
      if (stop != chosenStopPosition && (stop == stopPositions.first || stop == stopPositions.last)) {
        continue;
      }
      if (stop == chosenStopPosition) {
        customMarkerIcon = customMarkerIconFuture;
        isLargeMarker = true;
        continue;
      }

      Marker currentMarker = Marker(
        markerId: MarkerId('$stop'),
        position: stop,
        icon: customMarkerIcon!,
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
      );

      if (isLargeMarker) {
        largeMarkers.add(currentMarker);
      } else {
        smallMarkers.add(currentMarker);
      }
    }

    if (stopPosition != null) {
      stopMarker = Marker(
        markerId: MarkerId('$chosenStopPosition'),
        position: chosenStopPosition!,
        icon: customStopMarkerIcon,
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
      );
    }

    firstMarker = Marker(
      markerId: MarkerId('${stopPositions.first}'),
      position: stopPositions.first,
      icon: customMarkerIconFuture,
      anchor: const Offset(0.5, 0.5),
      consumeTapEvents: true,
    );

    lastMarker = Marker(
      markerId: MarkerId('${stopPositions.last}'),
      position: stopPositions.last,
      icon: customMarkerIconFuture,
      anchor: const Offset(0.5, 0.5),
      consumeTapEvents: true,
    );


    return PolyLineMarkers(largeMarkers, smallMarkers, stopMarker, firstMarker, lastMarker);
  }

  Future<GeoPathAndStops> addStopsToGeoPath(List<LatLng> geoPath, {LatLng? chosenStopPosition, List<LatLng>? allStopPositions}) async {
    List<LatLng> stopsAlongGeoPath = [];
    LatLng? stopPositionAlongGeoPath = chosenStopPosition;
    List<LatLng> stopPositions = [];
    List<LatLng> newGeoPath = [...geoPath];
    allStopPositions != null ? stopPositions = allStopPositions : stopPositions.add(chosenStopPosition!);

    int insertionIndex = 0;
    for (var pos in stopPositions) {
      var pointOnGeoPath = GeoPathUtils.generatePointOnGeoPath(pos, newGeoPath); // creates a point on the geoPath
      stopsAlongGeoPath.add(pointOnGeoPath);

      // Find the correct index to insert the pointOnGeoPath
      if (!newGeoPath.contains(pointOnGeoPath) && pos == chosenStopPosition) {
        stopPositionAlongGeoPath = pointOnGeoPath;

        // Find the two closest points in geoPath to insert between them
        insertionIndex = 0;
        for (int i = 0; i < newGeoPath.length - 1; i++) {
          LatLng pointA = newGeoPath[i];
          LatLng pointB = newGeoPath[i + 1];

          // If closestPoint is between pointA and pointB
          if (GeoPathUtils.isBetween(pointOnGeoPath, pointA, pointB)) {
            insertionIndex = i + 1;
            break;
          }
        }

        // Insert the closest point at the correct position
        newGeoPath.insert(insertionIndex, pointOnGeoPath);
      }
    }

    return GeoPathAndStops(newGeoPath, stopsAlongGeoPath, stopPositionAlongGeoPath);
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
}