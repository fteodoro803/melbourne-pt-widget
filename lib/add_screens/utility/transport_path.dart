import 'dart:ui';

import 'package:flutter_project/add_screens/utility/map_utils.dart';
import 'package:flutter_project/add_screens/utility/time_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../ptv_info_classes/stop_info.dart';

class TransportPath {
  final List<LatLng> geoPath;
  final List<Stop>? stopsAlongRoute;
  Stop? selectedStop;
  final String? routeColour;
  final LatLng? markerPosition;

  late Polyline fullPolyLine;
  late Polyline? futurePolyLine;
  late Polyline? previousPolyLine;

  Set<Marker> allRouteMarkers = {};
  Set<Marker> futureRouteMarkers = {};
  Set<Marker> previousRouteMarkers = {};
  Marker? selectedStopMarker;
  late Marker firstStopMarker;
  late Marker lastStopMarker;

  bool showDirection = false;
  bool showStop = false;
  bool showFutureMarkers = false;
  bool showPreviousMarkers = false;
  MapUtils mapUtils = MapUtils();

  TransportPath(this.geoPath, this.stopsAlongRoute, this.selectedStop, this.routeColour, this.markerPosition);

  Future<void> initializeFullPath() async {
    // Early exit if GeoPath is empty
    if (geoPath.isEmpty || stopsAlongRoute == null
        || stopsAlongRoute!.isEmpty) {
      return;
    }

    await initializeRouteMarkers(stopsAlongRoute!);

    fullPolyLine = Polyline(
      polylineId: PolylineId('full_polyline'),
      color: ColourUtils.hexToColour(routeColour!),
      width: 9,
      points: geoPath,
    );
  }

  Future<void> initializeRouteMarkers(List<Stop> stopsAlongRoute) async {

    BitmapDescriptor? customMarkerIcon = await mapUtils.getResizedImage("assets/icons/Marker Filled.png", 9, 9);

    for (var stop in stopsAlongRoute) {
      var pos = LatLng(stop.latitude!, stop.longitude!);

      Marker currentMarker = Marker(
        markerId: MarkerId('${stop.id}'),
        position: pos,
        icon: customMarkerIcon,
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
      );

      if (stop == stopsAlongRoute.first) {
        firstStopMarker = currentMarker;
      } else if (stop == stopsAlongRoute.last) {
        lastStopMarker = currentMarker;
      } else {
        allRouteMarkers.add(currentMarker);
      }
    }
  }

  Set<Marker> get markers {
    Set<Marker> markers = {};

    if (showDirection) {
      if (showFutureMarkers) {
        markers = {...futureRouteMarkers};
      }
      if (showPreviousMarkers) {
        markers = {...markers, ...previousRouteMarkers};
      }
    } else if (showFutureMarkers) {
      markers = {...markers, ...allRouteMarkers};
    }

    if (showStop) {
      if (selectedStop!.id == stopsAlongRoute!.first.id) {
        markers.add(lastStopMarker);
      } else if (selectedStop!.id == stopsAlongRoute!.last.id) {
        markers.add(firstStopMarker);
      } else {
        markers.removeWhere((m) => m.markerId == MarkerId(selectedStop!.id.toString()));
        markers.add(firstStopMarker);
        markers.add(lastStopMarker);
      }
      markers.add(selectedStopMarker!);
    } else {
      markers.add(firstStopMarker);
      markers.add(lastStopMarker);
    }

    return markers;
  }

  Set<Polyline> get polyLines {
    Set<Polyline> polyLines = {};
    if (showDirection) {
      polyLines.add(previousPolyLine!);
      polyLines.add(futurePolyLine!);
    } else {
      polyLines.add(fullPolyLine);
    }
    return polyLines;
  }

  Future<void> setStop(Stop stop) async {
    showStop = true;
    selectedStop = stop;

    BitmapDescriptor? customStopMarkerIcon = await mapUtils.getResizedImage("assets/icons/Marker Filled.png", 20, 20);
    LatLng pos = LatLng(stop.latitude!, stop.longitude!);

    selectedStopMarker = Marker(
      markerId: MarkerId('${stop.id}'),
      position: pos,
      icon: customStopMarkerIcon,
      anchor: const Offset(0.5, 0.5),
      consumeTapEvents: true,
    );
  }

  void hideStopMarker() {
    showStop = false;
    selectedStop = null;
    selectedStopMarker = null;
  }

  Future<void> setDirection() async {
    showDirection = true;
    LatLng stopPosition = LatLng(selectedStop!.latitude!, selectedStop!.longitude!);

    GeoPathAndStops geoPathAndStop = await addStopToGeoPath(geoPath, stopPosition);

    List<LatLng> newGeoPath = geoPathAndStop.geoPathWithStop;
    LatLng stopPositionOnGeoPath = geoPathAndStop.stopPositionAlongGeoPath!;

    bool isReverseDirection = GeoPathUtils.reverseDirection(newGeoPath, stopsAlongRoute!);

    await splitMarkers(stopsAlongRoute!, stopPosition);
    splitPolyLine(newGeoPath, isReverseDirection, stopPositionOnGeoPath);
  }

  void hideDirection() {
    showDirection = false;
  }

  void splitPolyLine(List<LatLng> geoPath, bool isReverseDirection, LatLng stopPositionAlongGeoPath) {

    List<LatLng> newGeoPath = isReverseDirection ? geoPath.reversed.toList() : geoPath;
    List<LatLng> previousRoute = [];
    List<LatLng> futureRoute = List.from(newGeoPath);
    int? closestIndex;

    closestIndex = newGeoPath.indexOf(stopPositionAlongGeoPath);

    // Separate the coordinates into previous and future journey
    previousRoute = newGeoPath.sublist(0, closestIndex + 1);
    futureRoute = newGeoPath.sublist(closestIndex);

    previousPolyLine = Polyline(
      polylineId: PolylineId('previous_route_polyline'),
      color: Color(0xFFB6B6B6),
      width: 6,
      points: previousRoute,
    );

    // Add polyline for future journey
    futurePolyLine = Polyline(
      polylineId: PolylineId('future_route_polyline'),
      color: ColourUtils.hexToColour(routeColour!),
      width: 9,
      points: futureRoute,
    );
  }

  /// Sets markers 
  Future<void> splitMarkers(List<Stop> stops, LatLng stopPosition) async {

    BitmapDescriptor customMarkerIconFuture = await mapUtils.getResizedImage("assets/icons/Marker Filled.png", 9, 9);
    BitmapDescriptor customMarkerIconPrevious = await mapUtils.getResizedImage("assets/icons/Marker Filled.png", 7, 7);
    BitmapDescriptor customMarkerIcon = customMarkerIconPrevious;

    bool isFutureMarker = false;

    for (var stop in stops) {
      var pos = LatLng(stop.latitude!, stop.longitude!);
      if (pos != stopPosition && (stop == stops.first || stop == stops.last)) {
        continue;
      }
      if (pos == stopPosition) {
        customMarkerIcon = customMarkerIconFuture;
        isFutureMarker = true;
        continue;
      }

      Marker currentMarker = Marker(
        markerId: MarkerId('${stop.id}'),
        position: pos,
        icon: customMarkerIcon,
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
      );

      if (isFutureMarker) {
        futureRouteMarkers.add(currentMarker);
      } else {
        previousRouteMarkers.add(currentMarker);
      }
    }
  }

  /// Adds current stop to geoPath in order to split polyline by direction
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

  /// Changes polyline marker visibility on zoom change
  void onZoomChange(double zoom) {
    double zoomThresholdLarge = 12.8; // Zoom level threshold to hide the marker
    double zoomThresholdSmall = 13.4;

    if (zoom < zoomThresholdLarge) {
      showFutureMarkers = false;
      showPreviousMarkers = false;

    } else if (zoom < zoomThresholdSmall && zoom >= zoomThresholdLarge) {
      showFutureMarkers = true;
      showPreviousMarkers = false;
    }
    else {
      showFutureMarkers = true;
      showPreviousMarkers = true;
    }
  }
}