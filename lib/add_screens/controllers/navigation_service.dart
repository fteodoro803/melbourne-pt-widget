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

  Future<NavigationService> init() async {
    return this;
  }

  /// Handle back button navigation
  void handleBackNavigation() {
    // If we're in a nested sheet
    if (sheetController.navigationStack.isNotEmpty) {
      final originSheet = sheetController.currentSheet.value;

      // If there is no previous sheet (Nearby Stops/Route Details)
      if (sheetController.navigationStack.length == 1) {
        if (sheetController.isSheetExpanded.value) {
          sheetController.animateSheetTo(0.6);
          return;
        }
        if (originSheet.name == 'Nearby Stops') {
          mapController.clearMap();
          sheetController.showSheet.value = false;
          sheetController.popSheet();
          return;
        } else {
          Get.back();
          return;
        }
      }

      final destinationSheet = sheetController
          .navigationStack[sheetController.navigationStack.length - 2];

      // If we are navigating back to Stop Details
      if (destinationSheet.name == 'Stop Details') {
        mapController.tripPath?.hideDirection();
        mapController.renderTripPath(); // Reload map without direction
      }

      if (originSheet.name == 'Stop Details') {
        if (destinationSheet.name == 'Nearby Stops') {
          mapController.setGeoPath([]);
          mapController.clearMap();
          mapController.resetMarkers();
        } else if (destinationSheet.name == 'Route Details') {
          mapController.tripPath?.hideStopMarker();
          mapController.renderTripPath();
        }
      }

      sheetController.popSheet();
      return;
    }

    // If no sheets are active or we can't handle it with the sheet navigator
    Get.back(); // Use GetX navigation
  }

  /// Navigate to Nearby Stops with location
  Future<void> navigateToNearbyStops(LatLng pos, String address) async {
    sheetController.navigationStack.clear();

    Get.find<NearbyStopsController>().setAddress(address);
    await Get.find<NearbyStopsController>().setStops("all", 300);

    sheetController.pushSheet('Nearby Stops', null);
    sheetController.showSheet.value = true;
    sheetController.animateSheetTo(0.4);

    if (mapController.isNearbyStopsButtonToggled.value) {
      mapController.showNearbyStopMarkers();
    }
  }

  /// Navigate to Stop Details
  Future<void> navigateToStop(Stop stop, pt_route.Route route) async {
    String? originSheet = sheetController.currentSheet.value.name;
    pt_route.Route newRoute = route;

    if (originSheet == 'Nearby Stops' ||
        originSheet == 'Trip Details' ||
        originSheet == 'Stop Details') {
      newRoute = await searchUtils.initializeRoute(newRoute);
      await mapController.setTripPath(newRoute, stop: stop);
    }

    StopDetailsState newState = StopDetailsState(stop: stop, route: newRoute);
    sheetController.pushSheet('Stop Details', newState);

    sheetController.animateSheetTo(0.3);
    await mapController.tripPath?.setStop(stop);
    await mapController.renderTripPath();

    if (originSheet == 'Nearby Stops' || originSheet == 'Trip Details') {
      await mapController.showPolyLine();
    }
  }

  /// Navigate to Route Details
  Future<void> navigateToRoute(pt_route.Route route) async {
    pt_route.Route newRoute = await searchUtils.initializeRoute(route);

    sheetController.navigationStack.clear();
    RouteDetailsState newState = RouteDetailsState(route: newRoute);
    sheetController.pushSheet('Route Details', newState);

    sheetController.showSheet.value = true;
    sheetController.animateSheetTo(0.4);

    await mapController.setTripPath(newRoute);
    await mapController.renderTripPath();
    await mapController.showPolyLine();
  }

  /// Navigate to Trip Details
  Future<void> navigateToTrip(Trip trip, List<Disruption>? disruptions) async {
    await trip.updateDepartures(departureCount: 20);

    if (sheetController.navigationStack.isEmpty) {
      trip.route = await searchUtils.initializeRoute(trip.route!);
      await Get.find<MapController>().setTripPath(trip.route!);
    }

    TripDetailsState newState =
        TripDetailsState(trip: trip, disruptions: disruptions);
    sheetController.pushSheet('Trip Details', newState);
    sheetController.showSheet.value = true;

    await mapController.tripPath?.setStop(trip.stop!);
    await mapController.tripPath?.setDirection(true);
    await mapController.renderTripPath();
    await mapController.showPolyLine();
  }

  /// Navigate to Departure Details
  Future<void> navigateToDeparture(Trip trip, Departure departure) async {
    if (sheetController.currentSheet.value.name != 'Trip Details') {
      await mapController.tripPath?.setDirection(false);
      await mapController.renderTripPath();
      await mapController.showPolyLine();
    }

    DepartureDetailsState newState =
        DepartureDetailsState(trip: trip, departure: departure);
    sheetController.pushSheet('Departure Details', newState);
  }
}
