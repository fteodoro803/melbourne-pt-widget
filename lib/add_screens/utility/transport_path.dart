import 'dart:ui';

import 'package:flutter_project/add_screens/utility/map_utils.dart';
import 'package:flutter_project/add_screens/utility/time_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../ptv_info_classes/stop_info.dart';

class TransportPath {
  final List<LatLng> geoPath;
  final List<Stop>? stopsAlongRoute;
  final Stop? stop;
  final String? routeColour;
  final LatLng? markerPosition;

  Set<Marker> markers = {};
  Set<Polyline> polyLines = {};

  Set<Marker> largeMarkers = {};
  Set<Marker> smallMarkers = {};

  Marker? stopMarker;

  late Marker firstMarker;
  late Marker lastMarker;

  late Polyline futurePolyLine;
  late Polyline? previousPolyLine;

  bool isDirectionSpecified = false;
  MapUtils mapUtils = MapUtils();

  TransportPath(this.geoPath, this.stopsAlongRoute, this.stop, this.routeColour, this.markerPosition);

  void setDirection(bool isDirectionSpecified) {
    this.isDirectionSpecified = isDirectionSpecified;
  }

  /// Loads route geo path and stops on map
  Future<void> loadTransportPath() async {

    // Early exit if GeoPath is empty
    if (geoPath.isEmpty || stopsAlongRoute == null
        || stopsAlongRoute!.isEmpty) {
      return;
    }

    LatLng? stopPosition;

    if (stop != null) {
      stopPosition = LatLng(
          stop!.latitude!, stop!.longitude!);
    }

    List<LatLng> stopPositions = [];
    LatLng? chosenStopPositionAlongGeoPath = stopPosition;
    List<LatLng> newGeoPath = [...geoPath];

    for (var stop in stopsAlongRoute!) {
      var pos = LatLng(stop.latitude!, stop.longitude!);
      stopPositions.add(pos);
    }

    if (stopPosition != null) {
      GeoPathAndStops geoPathAndStop
      = await addStopToGeoPath(geoPath, stopPosition);

      newGeoPath = geoPathAndStop.geoPathWithStop;
      chosenStopPositionAlongGeoPath = geoPathAndStop.stopPositionAlongGeoPath!;
    }

    bool isReverseDirection = isDirectionSpecified
        ? GeoPathUtils.reverseDirection(newGeoPath, stopPositions)
        : false;

    await setMarkers(
      stopPositions,
      stopPosition: stopPosition,
    );

    loadRoutePolyline(
      newGeoPath,
      stopPositionAlongGeoPath: chosenStopPositionAlongGeoPath,
      isReverseDirection
    );
  }

  /// Changes polyline marker visibility on zoom change
  void onZoomChange(double zoom) {
    double zoomThresholdLarge = 12.8; // Zoom level threshold to hide the marker
    double zoomThresholdSmall = 13.4;

    Set<Marker> newMarkers = {};

    if (zoom < zoomThresholdLarge) {

      if (stopMarker != null) {
        newMarkers.add(stopMarker!);
      }
      newMarkers.add(firstMarker);
      newMarkers.add(lastMarker);

    } else if (zoom < zoomThresholdSmall && zoom >= zoomThresholdLarge) {
      if (stopMarker != null) {
        newMarkers.add(stopMarker!);
      }
      newMarkers.add(firstMarker);
      newMarkers.add(lastMarker);
      newMarkers = {...newMarkers, ...largeMarkers};
    }
    else {
      // Re-add the marker when zoom is above the threshold
      newMarkers = {...markers, ...smallMarkers, ...largeMarkers};
    }
    markers = newMarkers;
  }

  void loadRoutePolyline(List<LatLng> geoPath, bool isReverseDirection, {LatLng? stopPositionAlongGeoPath}) {

    List<LatLng> newGeoPath = isReverseDirection ? geoPath.reversed.toList() : geoPath;
    List<LatLng> previousRoute = [];
    List<LatLng> futureRoute = List.from(newGeoPath);
    int? closestIndex;

    if (stopPositionAlongGeoPath != null) {
      closestIndex = newGeoPath.indexOf(stopPositionAlongGeoPath);

      // Separate the coordinates into previous and future journey
      previousRoute = newGeoPath.sublist(0, closestIndex + 1);
      futureRoute = isDirectionSpecified ? newGeoPath.sublist(closestIndex) : newGeoPath;
    }

    polyLines.clear();

    if (isDirectionSpecified) {
      // Add polyline for previous journey
      previousPolyLine = Polyline(
        polylineId: PolylineId('previous_route_polyline'),
        color: Color(0xFFB6B6B6),
        width: 6,
        points: previousRoute,
      );

      polyLines.add(previousPolyLine!);
    }

    // Add polyline for future journey
    futurePolyLine = Polyline(
      polylineId: PolylineId('future_route_polyline'),
      color: ColourUtils.hexToColour(routeColour!),
      width: 9,
      points: futureRoute,
    );

    polyLines.add(futurePolyLine);
  }

  Future<void> setMarkers(List<LatLng> stopPositions, {LatLng? stopPosition}) async {

    BitmapDescriptor? customMarkerIconFuture = await mapUtils.getResizedImage("assets/icons/Marker Filled.png", 9, 9);
    BitmapDescriptor? customMarkerIconPrevious = await mapUtils.getResizedImage("assets/icons/Marker Filled.png", 7, 7);

    BitmapDescriptor? customMarkerIcon = isDirectionSpecified
        ? customMarkerIconPrevious
        : customMarkerIconFuture;
    BitmapDescriptor? customStopMarkerIcon = await mapUtils.getResizedImage("assets/icons/Marker Filled.png", 20, 20);

    bool isLargeMarker = isDirectionSpecified ? false : true;

    for (var stop in stopPositions) {
      if (stop != stopPosition && (stop == stopPositions.first || stop == stopPositions.last)) {
        continue;
      }
      if (stop == stopPosition) {
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
        markerId: MarkerId('$stopPosition'),
        position: stopPosition,
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

    markers = {
      ...largeMarkers,
      ...smallMarkers
    };
    if (stopMarker != null) {
      markers.add(stopMarker!);
    }
    markers.add(firstMarker);
    markers.add(lastMarker);

  }

  Future<GeoPathAndStops> addStopToGeoPath(List<LatLng> geoPath, LatLng chosenStopPosition) async {
    LatLng? stopPositionAlongGeoPath = GeoPathUtils.generatePointOnGeoPath(chosenStopPosition, geoPath);
    List<LatLng> newGeoPath = [...geoPath];

    int insertionIndex = 0;
    for (int i = 0; i < newGeoPath.length - 1; i++) {
      LatLng pointA = newGeoPath[i];
      LatLng pointB = newGeoPath[i + 1];

      // If closestPoint is between pointA and pointB
      if (GeoPathUtils.isBetween(stopPositionAlongGeoPath, pointA, pointB)) {
        insertionIndex = i + 1;
        break;
      }
    }

    // Insert the closest point at the correct position
    newGeoPath.insert(insertionIndex, stopPositionAlongGeoPath);

    return GeoPathAndStops(newGeoPath, stopPositionAlongGeoPath);
  }

}