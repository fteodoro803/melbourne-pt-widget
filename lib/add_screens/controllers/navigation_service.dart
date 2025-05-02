// services/navigation_service.dart

import 'package:get/get.dart';
import 'package:flutter_project/domain/disruption.dart';
import 'package:flutter_project/add_screens/detail_sheets/departure_details.dart';
import 'package:flutter_project/add_screens/detail_sheets/route_details.dart';
import 'package:flutter_project/add_screens/detail_sheets/stop_details.dart';
import 'package:flutter_project/add_screens/detail_sheets/trip_details.dart';
import 'package:flutter_project/add_screens/utility/search_utils.dart';
import 'nearby_stops_controller.dart';
import 'sheet_controller.dart';
import 'map_controller.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/domain/route.dart' as pt_route;
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/domain/departure.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationService extends GetxService {
  SheetController get sheetController => Get.find<SheetController>();
  MapController get mapController => Get.find<MapController>();

  SearchUtils searchUtils = SearchUtils();

  final RxList<Map<String, dynamic>> _navigationStack = <Map<String, dynamic>>[].obs;
  dynamic stateToPush;
  final RxBool showSheet = false.obs;

  // Initialize the service
  Future<NavigationService> init() async {
    return this;
  }

  /// Handle back button navigation
  void handleBackNavigation() {
    final currentSheet = sheetController.currentSheet.value;
    final sheetHistory = sheetController.sheetHistory.toList();

    // If we're viewing Nearby Stops
    if (currentSheet == 'Nearby Stops') {
      mapController.clearMap();
      showSheet.value = false;
      sheetController.popSheet();
      _navigationStack.clear();
      return;
    }

    // If we're in a nested sheet
    if (sheetHistory.isNotEmpty) {
      final prevSheet = sheetHistory.last;

      // If there is no previous sheet (Nearby Stops/Route Details)
      if (prevSheet == "") {
        if (sheetController.isSheetExpanded.value) {
          sheetController.animateSheetTo(0.6);
          _navigationStack.clear();
          return;
        }
        else {
          Get.back();
          return;
        }
      }

      final previousSheet = _navigationStack.last;
      stateToPush = previousSheet['state'];
      // searchController.setState(previousSheet['state']);

      // If we are navigating back to Stop Details
      if (prevSheet == 'Stop Details') {
        mapController.tripPath?.hideDirection();
        mapController.renderTripPath(); // Reload map without direction
      }

      if (currentSheet == 'Stop Details') {
        if (prevSheet == 'Nearby Stops') {
          mapController.setGeoPath([]);
          mapController.clearMap();
          mapController.resetMarkers();

        } else if (prevSheet == 'Route Details') {
          mapController.tripPath?.hideStopMarker();
          mapController.renderTripPath();
        }
      }

      // Pop to previous sheet
      sheetController.popSheet();
      _navigationStack.removeAt(_navigationStack.length - 1);
      return;
    }

    // If no sheets are active or we can't handle it with the sheet navigator
    Get.back(); // Use GetX navigation
  }

  /// Navigate to Nearby Stops with location
  Future<void> navigateToNearbyStops(LatLng pos, String address) async {
    _navigationStack.clear();

    Get.find<NearbyStopsController>().setAddress(address);
    await Get.find<NearbyStopsController>().setStops("all", 300);

    sheetController.pushSheet('Nearby Stops');
    showSheet.value = true;
    sheetController.animateSheetTo(0.4);

    if (mapController.isNearbyStopsButtonToggled.value) {
      mapController.showNearbyStopMarkers();
    }
  }

  /// Navigate to Stop Details
  Future<void> navigateToStop(Stop stop, pt_route.Route route, dynamic currentState) async {
    String currentSheet = sheetController.currentSheet.value;
    pt_route.Route newRoute = route;

    if (currentSheet == 'Nearby Stops' || currentSheet == 'Trip Details') {
      newRoute = await searchUtils.initializeRoute(route);
      await mapController.setTripPath(newRoute, stop: stop);
    }

    _navigationStack.add({'type': currentSheet, 'state': currentState});

    StopDetailsState newState = StopDetailsState(stop: stop, route: newRoute);
    stateToPush = newState;

    sheetController.pushSheet('Stop Details');

    sheetController.animateSheetTo(0.3);
    await mapController.tripPath?.setStop(stop);
    await mapController.renderTripPath();

    if (currentSheet == 'Nearby Stops' || currentSheet == 'Trip Details') {
      await mapController.showPolyLine();
    }
  }

  /// Navigate to Route Details
  Future<void> navigateToRoute(pt_route.Route route) async {
    pt_route.Route newRoute = await searchUtils.initializeRoute(route);

    _navigationStack.clear();
    RouteDetailsState newState = RouteDetailsState(route: newRoute);
    stateToPush = newState;

    sheetController.pushSheet('Route Details');
    showSheet.value = true;
    sheetController.animateSheetTo(0.4);

    await mapController.setTripPath(newRoute);
    await mapController.renderTripPath();
    await mapController.showPolyLine();
  }

  /// Navigate to Trip Details
  Future<void> navigateToTrip(Trip trip, List<Disruption>? disruptions, dynamic state) async {
    await trip.updateDepartures(departureCount: 20);

    TripDetailsState newState = TripDetailsState(trip: trip, disruptions: disruptions);
    stateToPush = newState;

    if (_navigationStack.isEmpty) {
      await Get.find<MapController>().setTripPath(trip.route!);
    } else {
      _navigationStack.add({'type': sheetController.currentSheet.value, 'state': state});
    }

    sheetController.pushSheet('Trip Details');
    showSheet.value = true;

    await mapController.tripPath?.setStop(trip.stop!);
    await mapController.tripPath?.setDirection(true);
    await mapController.renderTripPath();
    await mapController.showPolyLine();
  }

  /// Navigate to Departure Details
  Future<void> navigateToDeparture(Trip trip, Departure departure, dynamic state) async {
    _navigationStack.add({'type': sheetController.currentSheet.value, 'state': state});

    DepartureDetailsState newState = DepartureDetailsState(trip: trip, departure: departure);
    stateToPush = newState;

    if (sheetController.currentSheet.value != 'Trip Details') {
      await mapController.tripPath?.setDirection(false);
      await mapController.renderTripPath();
      await mapController.showPolyLine();
    }
    sheetController.pushSheet('Departure Details');
  }
}