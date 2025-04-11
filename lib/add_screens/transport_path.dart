import 'package:flutter_project/add_screens/utility/map_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../ptv_info_classes/stop_info.dart';

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

  late Marker? stopMarker;

  late Marker firstMarker;
  late Marker lastMarker;

  late Polyline futurePolyLine;
  late Polyline? previousPolyLine;

  bool isDirectionSpecified = false;

  TransportPath(this.geoPath, this.stopsAlongRoute, this.stop, this.routeColour, this.markerPosition);

  void setDirection(bool isDirectionSpecified) {
    this.isDirectionSpecified = isDirectionSpecified;
  }

  /// Loads route geo path and stops on map
  Future<void> loadTransportPath() async {
    TransportPathUtils transportPathUtils = TransportPathUtils();

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
      = await transportPathUtils.addStopToGeoPath(geoPath, stopPosition);

      newGeoPath = geoPathAndStop.geoPathWithStop;
      chosenStopPositionAlongGeoPath = geoPathAndStop.stopPositionAlongGeoPath!;
    }

    bool isReverseDirection = isDirectionSpecified
        ? GeoPathUtils.reverseDirection(newGeoPath, stopPositions)
        : false;

    PolyLineMarkers polyLineMarkers = await transportPathUtils.setMarkers(
      markers,
      stopPositions,
      stopPosition: stopPosition,
      isDirectionSpecified,
    );

    stopMarker = polyLineMarkers.stopMarker;
    firstMarker = polyLineMarkers.firstMarker;
    lastMarker = polyLineMarkers.lastMarker;
    largeMarkers = polyLineMarkers.largeMarkers;
    smallMarkers = polyLineMarkers.smallMarkers;

    markers = {
      ...markers,
      ...polyLineMarkers.largeMarkers,
      ...polyLineMarkers.smallMarkers
    };
    if (polyLineMarkers.stopMarker != null) {
      markers.add(polyLineMarkers.stopMarker!);
    }
    markers.add(polyLineMarkers.firstMarker);
    markers.add(polyLineMarkers.lastMarker);

    PolyLines allPolyLines = await transportPathUtils.loadRoutePolyline(
        routeColour!,
        newGeoPath,
        stopPositionAlongGeoPath: chosenStopPositionAlongGeoPath,
        isDirectionSpecified,
        isReverseDirection
    );
    futurePolyLine = allPolyLines.futurePolyLine;
    previousPolyLine = allPolyLines.previousPolyLine;

    polyLines.add(allPolyLines.futurePolyLine);
    if (allPolyLines.previousPolyLine != null) {
      polyLines.add(allPolyLines.previousPolyLine!);
    }
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
}