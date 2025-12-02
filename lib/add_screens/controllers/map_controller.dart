// controllers/map_controller.dart

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter_project/add_screens/controllers/sheet_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import 'package:flutter_project/domain/route.dart' as pt_route;
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/services/ptv_service.dart';
import 'package:flutter_project/add_screens/utility/map_utils.dart';
import 'package:flutter_project/add_screens/utility/trip_path.dart';

import '../../services/gtfs_service.dart';
import 'navigation_service.dart';
import 'nearby_stops_controller.dart';

class MapController extends GetxController {
  final CustomInfoWindowController infoWindowController =
      CustomInfoWindowController();
  late GoogleMapController mapController;

  NavigationService get navigationService => Get.find<NavigationService>();
  NearbyStopsController get nearbyStopsController =>
      Get.find<NearbyStopsController>();
  SheetController get sheetController => Get.find<SheetController>();

  final MapUtils mapUtils = MapUtils();
  final PtvService ptvService = Get.find<PtvService>();
  final GtfsService gtfsService = Get.find<GtfsService>();

  late Circle radiusCircle;
  LatLng? markerPos;
  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Circle> circles = <Circle>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  List<LatLng> geoPath = [];
  Set<Marker> nearbyStopMarkers = {};
  TripPath? tripPath;

  String? tappedStopId;
  Marker? tappedStopMarker;
  Marker? locationMarker;

  RxDouble currentZoom = 15.0.obs;
  Rx<LatLng> currentPosition =
      LatLng(-37.813812122509205, 144.96358311072478).obs;

  RxBool isNearbyStopsButtonToggled = false.obs;
  bool areNearbyStopMarkersInitialized = false;
  bool shouldRenderMarkers = false;

  /// On pin drop
  Future<void> onLocationSelected(LatLng location) async {
    areNearbyStopMarkersInitialized = false;
    clearMap();
    markerPos = location;

    MarkerId id = MarkerId(markerPos.toString());

    locationMarker = Marker(
      markerId: id,
      position: markerPos!,
      consumeTapEvents: true,
    );
    resetMarkers();

    String address = await mapUtils.getAddressFromCoordinates(
        location.latitude, location.longitude);

    await navigationService.navigateToNearbyStops(markerPos!, address);

    await mapUtils.moveCameraToFitRadiusWithVerticalOffset(
        controller: mapController,
        center: location,
        radiusInMeters: nearbyStopsController.distanceInMeters);
  }

  /// Initializes nearby stop markers (on pin drop/filter change)
  Future<void> initialiseNearbyStopMarkers() async {
    tappedStopId = null;
    tappedStopMarker = null;
    List<Stop> stops = nearbyStopsController.filteredStops;

    radiusCircle = Circle(
        circleId: CircleId("circle"),
        center: markerPos!,
        fillColor: Colors.blue.withValues(alpha: 0.2),
        strokeWidth: 0,
        radius: nearbyStopsController.distanceInMeters);

    if (stops.isEmpty) {
      nearbyStopMarkers.clear();
    } else {
      Set<Marker> newNearbyStopMarkers =
          await mapUtils.generateNearbyStopMarkers(
        stops: stops,
        getIcon: (stop) => mapUtils.getResizedImage(
          "assets/icons/PTV ${stop.routeType!.name} Logo.png",
          20,
          20,
        ),
        onTapStop: handleNearbyStopTap,
      );

      nearbyStopMarkers
        ..clear()
        ..addAll(newNearbyStopMarkers);
    }
  }

  /// Shows nearby stops on map
  Future<void> showNearbyStopMarkers() async {
    if (!areNearbyStopMarkersInitialized) {
      await initialiseNearbyStopMarkers();
    }

    isNearbyStopsButtonToggled.value = true;

    Set<Marker> newMarkers = {};
    newMarkers.add(locationMarker!);
    markers.assignAll({
      ...newMarkers,
      ...nearbyStopMarkers,
    });

    circles.assignAll({radiusCircle});
  }

  /// Hides nearby stops from map
  void hideNearbyStopMarkers() {
    isNearbyStopsButtonToggled.value = false;

    if (locationMarker != null) {
      markers = {locationMarker!}.obs;
    } else {
      markers.clear();
    }

    circles.clear();
    infoWindowController.hideInfoWindow!();
  }

  /// Handles tapping on a nearby stop on map
  void handleNearbyStopTap(Stop stop) async {
    final largeIcon = await mapUtils.getResizedImage(
        "assets/icons/${stop.routeType?.name} Marker.png", 35, 55);

    for (var s in nearbyStopsController.stops) {
      nearbyStopsController.setStopExpanded(s.id, false);
    }
    nearbyStopsController.setStopExpanded(stop.id, true);

    if (tappedStopId != null) {
      markers.removeWhere((m) => m.markerId == MarkerId(tappedStopId!));
      markers.add(tappedStopMarker!);
    }

    tappedStopMarker =
        markers.firstWhere((m) => m.markerId == MarkerId(stop.id.toString()));
    markers.removeWhere((m) => m.markerId == MarkerId(stop.name));

    tappedStopId = stop.id.toString();
    markers.add(Marker(
      markerId: MarkerId(tappedStopId!),
      position: LatLng(stop.latitude!, stop.longitude!),
      icon: largeIcon,
      consumeTapEvents: true,
    ));

    infoWindowController.addInfoWindow!(
      StopInfoWindow(stop: stop),
      LatLng(stop.latitude!, stop.longitude!),
    );

    int stopIndex = nearbyStopsController.filteredStops.indexOf(stop);
    sheetController.animateSheetTo(0.7);
    nearbyStopsController.scrollToStopItem(stopIndex);
  }

  /// Initializes trip path for a new route
  Future<void> setTripPath(pt_route.Route route, {Stop? stop}) async {
    // List<LatLng> geoPath = await ptvService.fetchGeoPath(route);
    String? gtfsRouteId = await gtfsService.convertPtvRouteToGtfs(route);

    if (gtfsRouteId == null || gtfsRouteId.isEmpty) {
      print("( map_controller.dart -> setTripPath ) -- gtfsRouteId is null or empty");
      return;
    }

    List<LatLng> geoPath = await gtfsService.schedule.fetchGeoPath(gtfsRouteId);

    print(geoPath);
    setGeoPath(geoPath);

    tripPath = TripPath(
        geoPath, route.stopsAlongRoute, stop, route.colour!, markerPos);
    await tripPath!.initializeFullPath();
  }

  /// Renders full polyline on map
  Future<void> renderTripPath() async {
    hideNearbyStopMarkers();

    polylines.assignAll(tripPath!.polyLines);
    shouldRenderMarkers = false;

    await Future.delayed(Duration(milliseconds: 300));
    shouldRenderMarkers = true;
    tripPath?.onZoomChange(currentZoom.value);

    if (locationMarker != null) {
      markers.assignAll({locationMarker!, ...tripPath!.markers});
    } else {
      markers = {...tripPath!.markers}.obs;
    }
  }

  /// Updates zoom/center of map to show chosen polyline segment
  Future<void> showPolyLine() async {
    if (tripPath!.polyLines.isNotEmpty && geoPath.isNotEmpty) {
      await mapUtils.centerMapOnPolyLine(
        tripPath!.showDirection ? tripPath!.futurePolyLine!.points : geoPath,
        mapController,
        Get.context!,
        true,
      );
    }
  }

  /// Handles zoom and camera move events
  void onCameraMove(CameraPosition position) {
    if (sheetController.currentSheet.value != "Nearby Stops" &&
        currentZoom.value != position.zoom &&
        shouldRenderMarkers) {
      if (mapUtils.didZoomChange(currentZoom.value, position.zoom)) {
        tripPath?.onZoomChange(position.zoom);

        if (locationMarker != null) {
          markers.assignAll({locationMarker!, ...tripPath?.markers ?? {}});
        } else {
          markers = {...tripPath?.markers ?? {}}.obs;
        }

        currentZoom.value = position.zoom;
      }
    } else {
      currentZoom.value = position.zoom;
      infoWindowController.onCameraMove!();
    }
  }

  /// On map initialization
  void setController(GoogleMapController controller) {
    mapController = controller;
    infoWindowController.googleMapController = controller;
  }

  /// Clears all polyLines, markers, and circles
  void clearMap() {
    markers.clear();
    circles.clear();
    polylines.clear();
    nearbyStopMarkers.clear();
    clearTripPath();
    infoWindowController.hideInfoWindow!();
  }

  /// Clears markers set and adds primary marker if location is set
  void resetMarkers() {
    if (locationMarker != null) {
      markers = {locationMarker!}.obs;
    } else {
      markers.clear();
    }
  }

  void clearTripPath() => tripPath = null;
  void setGeoPath(List<LatLng> newGeoPath) => geoPath = newGeoPath;
}
