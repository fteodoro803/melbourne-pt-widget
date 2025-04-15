// controllers/map_controller.dart

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter_project/add_screens/controllers/sheet_navigator_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../ptv_info_classes/stop_info.dart';
import '../utility/map_utils.dart';
import '../utility/transport_path.dart';
import '../widgets/screen_widgets.dart';
import 'nearby_stops_controller.dart';
import '../controllers/search_controller.dart' as search_controller;

class MapController extends GetxController {
  final CustomInfoWindowController customInfoWindowController
    = CustomInfoWindowController();
  search_controller.SearchController get searchController =>
      Get.find<search_controller.SearchController>();
  late GoogleMapController mapController;

  final MapUtils mapUtils = MapUtils();

  late Circle radiusCircle;
  LatLng? markerPos;
  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Circle> circles = <Circle>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  Set<Marker> nearbyStopMarkers = {};
  TransportPath? transportPath;

  String? tappedStopId;
  Marker? tappedStopMarker;

  RxDouble currentZoom = 15.0.obs;
  Rx<LatLng> currentPosition = LatLng(-37.813812122509205,
      144.96358311072478).obs;

  RxBool isNearbyStopsButtonToggled = false.obs;

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
    clearTransportPath();
  }

  /// Clears markers set and adds primary marker if location is set
  void resetMarkers() {
    Set<Marker> newMarkers = {};
    if (markerPos != null) {
      MarkerId id = MarkerId(markerPos.toString());

      newMarkers.add(Marker(
        markerId: id,
        position: markerPos!,
        consumeTapEvents: true,
      ));
    }
    markers.assignAll(newMarkers);
  }

  void clearTransportPath() {
    transportPath = null;
  }

  /// On pin drop
  Future<void> onLocationSelected(LatLng location) async {
    clearMap();
    markerPos = location;
    resetMarkers();


    String address = await mapUtils.getAddressFromCoordinates(
        location.latitude,
        location.longitude
    );

    await searchController.pushLocation(location, address);
    mapUtils.moveCameraToFitRadiusWithVerticalOffset(
        controller: mapController,
        center: location,
        radiusInMeters: double.parse(
            Get.find<NearbyStopsController>().selectedUnit.value == "m"
                ? Get.find<NearbyStopsController>().selectedDistance.value
                : Get.find<NearbyStopsController>().selectedDistance.value * 1000
        ));

    // await initialiseNearbyStopMarkers();
  }

  Future<void> initialiseNearbyStopMarkers() async {
    customInfoWindowController.hideInfoWindow!();
    tappedStopId = null;
    tappedStopMarker = null;
    List<Stop> stops = Get.find<NearbyStopsController>().filteredStops;

    // Always update circle regardless of stop list
    radiusCircle = Circle(
      circleId: CircleId("circle"),
      center: markerPos!,
      fillColor: Colors.blue.withValues(alpha: 0.2),
      strokeWidth: 0,
      radius: double.parse(
        Get.find<NearbyStopsController>().selectedUnit.value == "m"
            ? Get.find<NearbyStopsController>().selectedDistance.value
            : Get.find<NearbyStopsController>().selectedDistance.value * 1000
      ),
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

    resetMarkers();
    markers.assignAll({
      ...markers,
      ...nearbyStopMarkers,
    });

    circles.assignAll({radiusCircle});
  }

  void hideNearbyStopMarkers() {
    isNearbyStopsButtonToggled.value = false;

    resetMarkers();
    circles.clear();
    customInfoWindowController.hideInfoWindow!();
  }

  void handleStopTapOnMap(Stop stop) async {
    final largeIcon = await mapUtils.getResizedImage(
        "assets/icons/PTV ${stop.routeType?.name} Logo Outlined.png", 35, 35);

    for (var s in searchController.details.value.stops!) {
      searchController.setStopExpanded(s.id, false);
    }
    searchController.setStopExpanded(stop.id, true);

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

    Get.find<SheetNavigationController>().animateSheetTo(0.6);

    Future.delayed(Duration(milliseconds: 100), () {
      Get.find<NearbyStopsController>().scrollToStopItem(stopIndex);
    });
  }

  void setTransportPath() {
    transportPath = TransportPath(
        searchController.details.value.geoPath!,
        searchController.details.value.route!.stopsAlongRoute,
        searchController.details.value.stop,
        searchController.details.value.route!.colour!,
        markerPos
    );
  }

  Future<void> renderTransportPath(bool showDirection) async {
    hideNearbyStopMarkers();

    transportPath?.setDirection(showDirection);
    await transportPath?.loadTransportPath();

    polylines.assignAll(transportPath!.polyLines);

    /// Move camera to show marker
    if (transportPath!.polyLines.isNotEmpty &&
        searchController.details.value.geoPath!.isNotEmpty) {
      await mapUtils.centerMapOnPolyLine(
        showDirection ? transportPath!.futurePolyLine.points : searchController
            .details.value.geoPath!,
        mapController,
        Get.context!,
        true,
      );
    }

    resetMarkers();
    markers.assignAll({
      ...markers,
      ...transportPath!.markers,
    });
  }

  /// Handles zoom and camera move events
  void onCameraMove(CameraPosition position) {
    if (searchController.details.value.stop != null
        && currentZoom.value != position.zoom) {
      if (mapUtils.didZoomChange(currentZoom.value, position.zoom)) {
        transportPath?.onZoomChange(position.zoom);
        resetMarkers();
        markers.assignAll({
          ...markers,
          ...transportPath?.markers ?? {}});
        currentZoom.value = position.zoom;
      }
    }
    else {
      customInfoWindowController.onCameraMove!();
    }
  }
}


