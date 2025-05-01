// controllers/map_controller.dart

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter_project/add_screens/controllers/sheet_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/route.dart' as pt_route;
import '../../domain/stop.dart';
import '../../ptv_service.dart';
import 'navigation_service.dart';
import '../utility/map_utils.dart';
import '../utility/trip_path.dart';
import 'nearby_stops_controller.dart';

class MapController extends GetxController {
  final CustomInfoWindowController customInfoWindowController
    = CustomInfoWindowController();
  late GoogleMapController mapController;

  NavigationService get navigationService {
    return Get.find<NavigationService>();
  }

  final MapUtils mapUtils = MapUtils();
  PtvService ptvService = PtvService();

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
  Rx<LatLng> currentPosition = LatLng(-37.813812122509205,
      144.96358311072478).obs;

  RxBool isNearbyStopsButtonToggled = false.obs;
  bool shouldRenderMarkers = false;

  /// On map initialization
  void setController(GoogleMapController controller) {
    mapController = controller;
    customInfoWindowController.googleMapController = controller;
  }

  void clearMap() {
    markers.clear();
    circles.clear();
    polylines.clear();
    nearbyStopMarkers.clear();
    clearTripPath();
    customInfoWindowController.hideInfoWindow!();
  }

  /// Clears markers set and adds primary marker if location is set
  void resetMarkers() {
    if (locationMarker != null) {
      markers = {locationMarker!}.obs;
    }
    else {
      markers.clear();
    }
  }

  void clearTripPath() {
    tripPath = null;
  }

  void setGeoPath(List<LatLng> newGeoPath) {
    geoPath = newGeoPath;
  }

  /// On pin drop
  Future<void> onLocationSelected(LatLng location) async {
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
      location.latitude,
      location.longitude
    );

    await navigationService.navigateToNearbyStops(markerPos!, address);

    Get.find<SheetController>().animateSheetTo(0.5);

    await mapUtils.moveCameraToFitRadiusWithVerticalOffset(
      controller: mapController,
      center: location,
      radiusInMeters: Get.find<NearbyStopsController>().distanceInMeters
    );
  }

  Future<void> initialiseNearbyStopMarkers() async {
    // customInfoWindowController.hideInfoWindow!();
    tappedStopId = null;
    tappedStopMarker = null;
    List<Stop> stops = Get.find<NearbyStopsController>().filteredStops;

    // Always update circle regardless of stop list
    radiusCircle = Circle(
      circleId: CircleId("circle"),
      center: markerPos!,
      fillColor: Colors.blue.withValues(alpha: 0.2),
      strokeWidth: 0,
      radius: Get.find<NearbyStopsController>().distanceInMeters
    );

    // Handle nearby stop markers
    if (stops.isEmpty) {
      nearbyStopMarkers.clear();
    } else {
      Set<Marker> newNearbyStopMarkers = await mapUtils.generateNearbyStopMarkers(
        stops: stops,
        getIcon: (stop) => mapUtils.getResizedImage(
          "assets/icons/PTV ${stop.routeType!.name} Logo.png",
          20,
          20,
        ),
        onTapStop: handleStopTapOnMap,
      );

      nearbyStopMarkers
        ..clear()
        ..addAll(newNearbyStopMarkers);
    }

    // Always update map if the toggle is on
    if (isNearbyStopsButtonToggled.value) {
      await showNearbyStopMarkers();
    }
  }

  Future<void> showNearbyStopMarkers() async {
    isNearbyStopsButtonToggled.value = true;

    Set<Marker> newMarkers = {};
    newMarkers.add(locationMarker!);
    markers.assignAll({
      ...newMarkers,
      ...nearbyStopMarkers,
    });

    circles.assignAll({radiusCircle});
  }

  void hideNearbyStopMarkers() {
    isNearbyStopsButtonToggled.value = false;

    if (locationMarker != null) {
      markers = {locationMarker!}.obs;
    } else {
      markers.clear();
    }

    circles.clear();
    customInfoWindowController.hideInfoWindow!();
  }

  void handleStopTapOnMap(Stop stop) async {
    final largeIcon = await mapUtils.getResizedImage(
        "assets/icons/${stop.routeType?.name} Marker.png", 35, 55);

    for (var s in Get.find<NearbyStopsController>().stops) {
      Get.find<NearbyStopsController>().setStopExpanded(s.id, false);
    }
    Get.find<NearbyStopsController>().setStopExpanded(stop.id, true);

    if (tappedStopId != null) {
      markers.removeWhere((m) => m.markerId == MarkerId(tappedStopId!));
      markers.add(tappedStopMarker!);
    }

    tappedStopMarker = markers.firstWhere(
            (m) => m.markerId == MarkerId(stop.id.toString()));
    markers.removeWhere((m) => m.markerId == MarkerId(stop.name));

    tappedStopId = stop.id.toString();
    markers.add(Marker(
      markerId: MarkerId(tappedStopId!),
      position: LatLng(stop.latitude!, stop.longitude!),
      icon: largeIcon,
      consumeTapEvents: true,
    ));

    customInfoWindowController.addInfoWindow!(
      StopInfoWindow(stop: stop),
      LatLng(stop.latitude!, stop.longitude!),
    );

    int stopIndex = Get.find<NearbyStopsController>().filteredStops.indexOf(stop);
    Get.find<SheetController>().animateSheetTo(0.7);
    Get.find<NearbyStopsController>().scrollToStopItem(stopIndex);
  }
  
  Future<void> setTripPath(pt_route.Route route, {Stop? stop}) async {
    List<LatLng> geoPath = await ptvService.fetchGeoPath(route);
    setGeoPath(geoPath);

    tripPath = TripPath(
        geoPath,
        route.stopsAlongRoute,
        stop,
        route.colour!,
        markerPos
    );
    await tripPath!.initializeFullPath();
  }

  Future<void> showPolyLine() async {
    /// Move camera to show marker
    if (tripPath!.polyLines.isNotEmpty && geoPath.isNotEmpty) {
      await mapUtils.centerMapOnPolyLine(
        tripPath!.showDirection ? tripPath!.futurePolyLine!.points : geoPath,
        mapController,
        Get.context!,
        true,
      );
    }
  }

  Future<void> renderTripPath() async {
    hideNearbyStopMarkers();

    polylines.assignAll(tripPath!.polyLines);
    shouldRenderMarkers = false;

    await Future.delayed(Duration(milliseconds: 300));
    shouldRenderMarkers = true;
    tripPath?.onZoomChange(currentZoom.value);

    if (locationMarker != null) {
      markers.assignAll({
        locationMarker!,
        ...tripPath!.markers});
    } else {
      markers = {...tripPath!.markers}.obs;
    }
  }

  /// Handles zoom and camera move events
  void onCameraMove(CameraPosition position) {
    if (Get.find<SheetController>().currentSheet.value != "Nearby Stops" && currentZoom.value != position.zoom && shouldRenderMarkers) {
      if (mapUtils.didZoomChange(currentZoom.value, position.zoom)) {
        tripPath?.onZoomChange(position.zoom);

        if (locationMarker != null) {
          markers.assignAll({
            locationMarker!,
            ...tripPath?.markers ?? {}});
        } else {
          markers = {...tripPath?.markers ?? {}}.obs;
        }

        currentZoom.value = position.zoom;
      }
    }
    else {
      currentZoom.value = position.zoom;
      customInfoWindowController.onCameraMove!();
    }
  }
}


