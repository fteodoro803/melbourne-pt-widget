// controllers/search_details_controller.dart

import 'package:flutter_project/add_screens/controllers/sheet_navigator_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/departure.dart';
import '../../domain/route_info.dart' as pt_route;
import '../../domain/stop_info.dart';
import '../../ptv_service.dart';
import '../../domain/trip.dart';
import '../utility/search_utils.dart';
import 'departure_details_controller.dart';
import 'map_controller.dart';

class SearchDetails {
  LatLng? markerPos;
  String? address;

  // Progressively narrowing down the search
  List<Stop>? stops = [];
  Stop? stop;
  pt_route.Route? route;
  List<LatLng>? geoPath = [];
  List<Trip>? transportList = [];
  Trip? transport;
  Departure? departure;

  SearchDetails();
  SearchDetails.withRoute(this.route);
  SearchDetails.withTransport(this.transport);
}

class SearchController extends GetxController {
  late Rx<SearchDetails> details = SearchDetails().obs;

  SheetNavigationController get sheetController => Get.find<SheetNavigationController>();

  final RxBool showSheet = false.obs;
  SearchUtils searchUtils = SearchUtils();
  PtvService ptvService = PtvService();

  RxMap<int, RxBool> stopExpansionState = <int, RxBool>{}.obs;

  void setDetails(SearchDetails searchDetails) {
    details = searchDetails.obs;
  }

  void handleBackButton() {
    final currentSheet = sheetController.currentSheet.value;
    final sheetHistory = sheetController.sheetHistory.toList();

    // Cases:
    // Departure details -> Transport Details
    // Departure details -> Stop details
    // Transport details -> Stop details
    // Stop details -> Route details
    // Stop details -> Nearby Stop details
    // Nearby Stop Details -> Empty map
    // Route details -> Find Routes Screen

    // If we're viewing Nearby Stops
    if (currentSheet == 'Nearby Stops') {
      resetDetails();
      Get.find<MapController>().clearMap();
      showSheet.value = false;
      sheetController.popSheet();
      return;
    }

    // If we're in a nested sheet
    if (sheetHistory.isNotEmpty) {
      final prevSheet = sheetHistory.last;

      // If there is no previous sheet (Nearby Stops/Route Details)
      if (prevSheet == "") {
        if (sheetController.isSheetExpanded()) {
          sheetController.animateSheetTo(0.6);
          return;
        }
        else {
          Get.back();
          return;
        }
      }

      // If we are navigating back to Stop Details
      if (prevSheet == 'Stop Details') {

        details.update((details) {
          details?.transport = null; // Clear transport
          if (currentSheet == 'Departure Details') {
            details?.departure = null; // Clear departures
          }
        });

        Get.find<MapController>().transportPath?.hideDirection();
        Get.find<MapController>().renderTransportPath(); // Reload map without direction
      }

      if (currentSheet == 'Stop Details') {
        // Reset stop and route state
        details.update((details) {
          details?.stop = null;
          details?.transportList = [];
          if (prevSheet == 'Nearby Stops') {
            details?.route = null;
          }
        });
        if (prevSheet == 'Nearby Stops') {
          // Reset map elements
          Get.find<MapController>().clearMap();
          Get.find<MapController>().resetMarkers();
        }
        else {
          Get.find<MapController>().transportPath?.hideStopMarker();
          Get.find<MapController>().renderTransportPath(); // Reload map without direction
        }
      }

      // Pop to previous sheet
      sheetController.popSheet();
      return;
    }

    // If no sheets are active or we can't handle it with the sheet navigator
    Get.back(); // Use GetX navigation
  }

  /// Clears all search data
  void resetDetails() {
    details.value = SearchDetails();
  }

  /// Triggers opening Nearby Stops Sheet & loading map markers
  Future<void> pushLocation(LatLng pos, String address) async {
    resetDetails();
    details.update((d) => d?.address = address);
    details.update((d) => d?.markerPos = pos);

    await setStops("all", 300);
    sheetController.pushSheet('Nearby Stops');
    showSheet.value = true;
    Get.find<SheetNavigationController>().animateSheetTo(0.4);
    await Get.find<MapController>().initialiseNearbyStopMarkers();
  }

  /// Triggers loading Stop Details Sheet from Route Details/Nearby Stops
  Future<void> pushStop(Stop stop) async { // todo: show marker of given stop
    setStop(stop);
    await setTransportList();
    if (sheetController.currentSheet.value == 'Nearby Stops') {
      await Get.find<MapController>().setTransportPath();
    }
    sheetController.pushSheet('Stop Details');

    Get.find<SheetNavigationController>().animateSheetTo(0.3);
    await Get.find<MapController>().transportPath?.setStop(stop);
    await Get.find<MapController>().renderTransportPath();
  }

  /// Triggers loading Route Details Sheet
  Future<void> pushRoute() async {
    await setRoute(details.value.route!);

    sheetController.pushSheet('Route Details');
    showSheet.value = true;
    Get.find<SheetNavigationController>().animateSheetTo(0.4);

    await Get.find<MapController>().setTransportPath();
    await Get.find<MapController>().renderTransportPath();
  }

  /// Triggers loading Transport Details Sheet
  Future<void> pushTransport(Trip transport) async {
    if (details.value.transport == null) {
      setTransport(transport);
    } else {
      setStop(details.value.transport!.stop!);
      await setRoute(details.value.transport!.route!);
      Get.find<MapController>().setTransportPath();
    }
    sheetController.pushSheet('Transport Details');
    showSheet.value = true;
    Get.find<SheetNavigationController>().animateSheetTo(0.5);
    await Get.find<MapController>().transportPath?.setDirection();
    await Get.find<MapController>().renderTransportPath();
  }

  /// Triggers loading Departure Details sheet from Stop Details/Transport Details)
  Future<void> pushDeparture(Departure departure) async {
    setDeparture(departure);

    if (sheetController.currentSheet.value != 'Transport Details') {
      await Get.find<MapController>().transportPath?.setDirection();
      await Get.find<MapController>().renderTransportPath();
    }
    sheetController.pushSheet('Departure Details');

    if (Get.isRegistered<DepartureDetailsController>()) {
      Get.find<DepartureDetailsController>().fetchPattern();
    }
  }

  /// Sets new stops list & initializes expansion states
  Future<void> setStops(String routeType, int distance) async {
    List<Stop> uniqueStops = await searchUtils.getStops(details.value.markerPos!, routeType, distance);

    details.update((d) => d?.stops = uniqueStops);

    resetStopExpanded();
  }

  void setStop(Stop stop) {
    details.update((d) => d?.stop = stop);
  }

  void resetStopExpanded() {
    for (var stop in details.value.stops!) {
      stopExpansionState[stop.id] = false.obs;
    }
  }

  void setStopExpanded(int stopId, bool expand) {
    if (stopExpansionState.containsKey(stopId)) {
      stopExpansionState[stopId]!.value = expand;
    } else {
      stopExpansionState[stopId] = expand.obs;
    }
  }

  /// Sets new route, and initializes route directions, stopsAlongRoute, and geoPath
  Future<void> setRoute(pt_route.Route route) async {
    details.update((d) => d?.route = route);

    details.value.route!.directions = await ptvService.fetchDirections(details.value.route!.id);

    details.value.route!.stopsAlongRoute =
    await searchUtils.getStopsAlongRoute(
        details.value.route!.directions!, details.value.route!);

    details.value.geoPath = await ptvService.fetchGeoPath(details.value.route!);
  }

  /// Sets new transport list based on stop and route pair
  Future<void> setTransportList() async {
    List<Trip> newTransportList =
    await searchUtils.splitDirection(details.value.stop!, details.value.route!);

    details.update((d) => d?.transportList = newTransportList);
  }

  void setTransport(Trip transport) {
    details.update((d) => d?.transport = transport);
  }

  void setDeparture(Departure departure) {
    details.update((d) => d?.departure = departure);
  }
}