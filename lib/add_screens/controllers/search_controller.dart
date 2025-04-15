// controllers/search_details_controller.dart

import 'package:flutter_project/add_screens/controllers/sheet_navigator_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../ptv_info_classes/departure_info.dart';
import '../../ptv_info_classes/route_info.dart' as pt_route;
import '../../ptv_info_classes/stop_info.dart';
import '../../ptv_service.dart';
import '../../transport.dart';
import '../utility/search_utils.dart';
import 'map_controller.dart';

class SearchDetails {
  LatLng? markerPos;
  String? address;

  // Progressively narrowing down the search
  List<Stop>? stops = [];
  Stop? stop;
  pt_route.Route? route;
  List<LatLng>? geoPath = [];
  List<Transport>? transportList = [];
  Transport? transport;
  Departure? departure;

  SearchDetails();
  SearchDetails.withRoute(this.route);
  SearchDetails.withTransport(this.transport);
}

class SearchController extends GetxController {
  late Rx<SearchDetails> details;

  SheetNavigationController get sheetController => Get.find<SheetNavigationController>();

  final RxBool showSheet = false.obs;
  SearchUtils searchUtils = SearchUtils();
  PtvService ptvService = PtvService();

  RxMap<int, RxBool> stopExpansionState = <int, RxBool>{}.obs;

  SearchController({
    required this.details,
  });

  void handleBackButton() {
    final currentSheet = sheetController.currentSheet.value;
    final sheetHistory = sheetController.sheetHistory.toList();

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
      if (prevSheet == 'Stop Details' &&
          (currentSheet == 'Transport Details' || currentSheet == 'Departure Details')) {
        // Reload map without direction
        Get.find<MapController>().renderTransportPath(false);
      }

      if (prevSheet == 'Nearby Stops' && currentSheet == 'Stop Details') {
        // Reset stop and route state
        details.update((details) {
          details?.stop = null;
          details?.route = null;
          details?.transportList = [];
        });

        // Reset map elements
        Get.find<MapController>().clearMap();
        Get.find<MapController>().resetMarkers();
      }

      // Pop to previous sheet
      sheetController.popSheet();
      return;
    }

    // If no sheets are active or we can't handle it with the sheet navigator
    Get.back(); // Use GetX navigation
  }


  /// Opens Route Details/Transport Details if enableSearch is false
  Future<void> autoOpenSheet() async {
    if (details.value.route != null) {
      await setRoute(details.value.route!);

      sheetController.pushSheet('Route Details');
      showSheet.value = true;

      Get.find<MapController>().setTransportPath();
      Get.find<MapController>().renderTransportPath(false);

    } else if (details.value.transport != null) {
      setStop(details.value.transport!.stop!);
      await setRoute(details.value.transport!.route!);
      setTransport(details.value.transport!);

      sheetController.pushSheet('Transport Details');
      showSheet.value = true;

      Get.find<MapController>().setTransportPath();
      Get.find<MapController>().renderTransportPath(true);
    }
  }

  /// Clears all map data
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
  }

  /// Triggers loading Stop Details Sheet from Route Details/Nearby Stops
  Future<void> pushStop(Stop stop) async {
    setStop(stop);
    await setTransportList();
    sheetController.pushSheet('Stop Details');

    Get.find<MapController>().setTransportPath();
    Get.find<MapController>().renderTransportPath(false);
  }

  /// Triggers loading Transport Details Sheet
  void pushTransport(Transport transport) {
    setTransport(transport);

    sheetController.pushSheet('Transport Details');
    Get.find<MapController>().renderTransportPath(true);
  }

  /// Triggers loading Departure Details sheet from Stop Details/Transport Details)
  void pushDeparture(Departure departure) {
    setDeparture(departure);
    sheetController.pushSheet('Departure Details');
    Get.find<MapController>().renderTransportPath(true);
  }

  /// Sets new stops list & initializes expansion states
  Future<void> setStops(String routeType, int distance) async {
    List<Stop> uniqueStops = await searchUtils.getStops(details.value.markerPos!, routeType, distance);

    details.update((d) => d?.stops = uniqueStops);

    for (var stop in details.value.stops!) {
      stopExpansionState[stop.id] = false.obs;
    }
  }

  void setStop(Stop stop) {
    details.update((d) => d?.stop = stop);
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
    List<Transport> newTransportList =
    await searchUtils.splitDirection(details.value.stop!, details.value.route!);

    details.update((d) => d?.transportList = newTransportList);
  }

  void setTransport(Transport transport) {
    details.update((d) => d?.transport = transport);
  }

  void setDeparture(Departure departure) {
    details.update((d) => d?.departure = departure);
  }
}