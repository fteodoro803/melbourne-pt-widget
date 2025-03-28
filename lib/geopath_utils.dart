import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/time_utils.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:async';

import 'package:flutter/material.dart';


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

class GeopathAndStops {
  final List<LatLng> geopath;
  final List<LatLng> stopsAlongGeopath;
  final LatLng stopPositionAlongGeopath;

  GeopathAndStops(this.geopath, this.stopsAlongGeopath, this.stopPositionAlongGeopath);
}

class TransportPathUtils {
  Future<Set<Polyline>> loadRoutePolyline(Transport transport, List<LatLng> geopath, LatLng stopPositionAlongGeopath, bool isDirectionSpecified) async {
    Set<Polyline> _polylines = {};

    int closestIndex = geopath.indexOf(stopPositionAlongGeopath);

    // Separate the coordinates into previous and future journey                  ADD IMPLEMENTATION FOR REVERSE DIRECTION !!!
    List<LatLng> previousRoute = geopath.sublist(0, closestIndex + 1);
    List<LatLng> futureRoute = isDirectionSpecified ? geopath.sublist(closestIndex) : geopath;

    if (isDirectionSpecified) {
      // Add polyline for previous journey
      _polylines.add(Polyline(
        polylineId: PolylineId('previous_route_polyline'),
        color: Color(0xFFB6B6B6),
        width: 6,
        points: previousRoute,
      ));
    }

    // Add polyline for future journey
    _polylines.add(Polyline(
      polylineId: PolylineId('future_route_polyline'),
      color: ColourUtils.hexToColour(transport.route!.colour!),
      width: 9,
      points: futureRoute,
    ));

    return _polylines;

  }

  Future<Set<Marker>> setMarkers(List<LatLng> stopsAlongGeopath, LatLng stopPositionAlongGeopath, LatLng? redMarkerPosition, bool isDirectionSpecified) async {
    Set<Marker> markers = {};

    BitmapDescriptor? customMarkerIconPrevious = await getResizedImage("assets/icons/Marker Filled.png", 8, 8);
    BitmapDescriptor? customMarkerIconFuture = await getResizedImage("assets/icons/Marker Filled.png", 10, 10);
    BitmapDescriptor? customMarkerIcon = isDirectionSpecified ? customMarkerIconFuture : customMarkerIconPrevious;
    BitmapDescriptor? customStopMarkerIcon = await getResizedImage("assets/icons/Marker Filled.png", 16, 16);


    for (var stop in stopsAlongGeopath) {
      if (stop == stopPositionAlongGeopath) {
        customMarkerIcon = customMarkerIconFuture;
        continue;
      }
      markers.add(Marker(
        markerId: MarkerId("$stop"),
        position: stop,
        icon: customMarkerIcon!,
      ));
    }
    // for (var stop in _stops) {
    //   _markers.add(Marker(
    //     markerId: MarkerId(stop.id),
    //     position: LatLng(stop.latitude!, stop.longitude!),
    //     icon: _customMarkerIconPrevious!,
    //   ));
    // }
    markers.add(Marker(
      markerId: MarkerId('center_marker'),
      position: stopPositionAlongGeopath,
      icon: customStopMarkerIcon,
    ));
    if (redMarkerPosition != null) {
      markers.add(Marker(
        markerId: MarkerId('position'),
        position: redMarkerPosition,
      ));
    }

    return markers;
  }

  Future<GeopathAndStops> addStopsToGeoPath(List<Stop> stops, List<LatLng> geopath, LatLng chosenStopPosition) async {
    List<LatLng> stopsAlongGeopath = [];
    LatLng stopPositionAlongGeopath = chosenStopPosition;

    for (var stop in stops) {
      var stopPosition = LatLng(stop.latitude!, stop.longitude!);
      var closestPoint = GeoPathUtils.findClosestPoint(stopPosition, geopath);
      stopsAlongGeopath.add(closestPoint);

      // Find the correct index to insert the closestPoint
      if (!geopath.contains(closestPoint) && stopPosition == chosenStopPosition) {
        stopPositionAlongGeopath = closestPoint;

        // Find the two closest points in _geopath to insert between them
        int insertionIndex = 0;
        for (int i = 0; i < geopath.length - 1; i++) {
          LatLng pointA = geopath[i];
          LatLng pointB = geopath[i + 1];

          // If closestPoint is between pointA and pointB
          if (GeoPathUtils.isBetween(closestPoint, pointA, pointB)) {
            insertionIndex = i + 1;
            break;
          }
        }

        // Insert the closest point at the correct position
        geopath.insert(insertionIndex, closestPoint);
      }
    }

    return GeopathAndStops(geopath, stopsAlongGeopath, stopPositionAlongGeopath);
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