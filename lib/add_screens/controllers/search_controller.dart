// controllers/search_details_controller.dart

import 'package:flutter_project/add_screens/controllers/sheet_navigator_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/departure.dart';
import '../../domain/route.dart' as pt_route;
import '../../domain/stop.dart';
import '../../ptv_service.dart';
import '../../domain/trip.dart';
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
  List<Trip> tripList = [];
  Trip? trip;
  Departure? departure;

  SearchDetails();
  SearchDetails.withRoute(this.route);
  SearchDetails.withTrip(this.trip);
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

    // new case: stop details -> trip details

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
        details.update((details) => details?.trip = null); // Clear trip
        for (var trip in details.value.tripList) {
          trip.updateDepartures(departureCount: 2);
        }

        Get.find<MapController>().tripPath?.hideDirection();
        Get.find<MapController>().renderTripPath(); // Reload map without direction
      }

      if (currentSheet == 'Departure Details') {
        details.update((details) => details?.departure = null);
        if (prevSheet == 'Trip Details') {
          details.value.trip!.updateDepartures(departureCount: 20);
        }
      }

      if (currentSheet == 'Stop Details') {
        // Reset stop and route state
        if (prevSheet != 'Trip Details') {
          details.update((details) {
            details?.stop = null;
            details?.tripList = [];
          });
        }
        if (prevSheet == 'Nearby Stops') {
          details.update((details) {
            details?.route = null;
            details?.geoPath = [];
          });
          Get.find<MapController>().clearMap();
          Get.find<MapController>().resetMarkers();
        } else if (prevSheet == 'Route Details') {
          Get.find<MapController>().tripPath?.hideStopMarker();
          Get.find<MapController>().renderTripPath();
        } else {                // Previous sheet is Route Details
          pushTrip(details.value.trip!); // todo: find better solution -- this fails when a new transport is set and you want to go back to an old transport
        }
      }

      // Pop to previous sheet
      sheetController.popSheet();
      return;
    }

    // If no sheets are active or we can't handle it with the sheet navigator
    Get.back(); // Use GetX navigation
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

  /// Triggers loading Stop Details Sheet from Route Details/Nearby Stops/TransportDetails
  Future<void> pushStop(Stop stop) async { // todo: show marker of given stop
    String currentSheet = sheetController.currentSheet.value;

    setStop(stop);
    await setTripList();
    if (currentSheet == 'Nearby Stops' || currentSheet == 'Trip Details') {
      await Get.find<MapController>().setTripPath();
    }
    sheetController.pushSheet('Stop Details');

    Get.find<SheetNavigationController>().animateSheetTo(0.3);
    await Get.find<MapController>().tripPath?.setStop(stop);
    await Get.find<MapController>().renderTripPath();

    if (currentSheet == 'Nearby Stops' || currentSheet == 'Trip Details') {
      await Get.find<MapController>().showPolyLine();
    }
  }

  /// Triggers loading Route Details Sheet
  Future<void> pushRoute() async {
    await setRoute(details.value.route!);

    sheetController.pushSheet('Route Details');
    showSheet.value = true;
    Get.find<SheetNavigationController>().animateSheetTo(0.4);

    await Get.find<MapController>().setTripPath();
    await Get.find<MapController>().renderTripPath();
    await Get.find<MapController>().showPolyLine();
  }

  /// Triggers loading Trip Details Sheet
  Future<void> pushTrip(Trip trip) async {
    if (details.value.trip == null) {
      setTrip(trip);
      await details.value.trip!.updateDepartures(departureCount: 20);
    } else {
      setStop(details.value.trip!.stop!);
      await setRoute(details.value.trip!.route!);
      await details.value.trip!.updateDepartures(departureCount: 20);
      Get.find<MapController>().setTripPath();
    }
    sheetController.pushSheet('Trip Details');
    showSheet.value = true;
    await Get.find<MapController>().tripPath?.setStop(details.value.trip!.stop!);
    if (details.value.tripList.isNotEmpty && trip.direction != details.value.tripList[0].direction) {
      await Get.find<MapController>().tripPath?.setDirection(true);
    } else {
      await Get.find<MapController>().tripPath?.setDirection(false);
    }

    await Get.find<MapController>().renderTripPath();
    await Get.find<MapController>().showPolyLine();
  }

  /// Triggers loading Departure Details sheet from Stop Details/Trip Details)
  Future<void> pushDeparture(Departure departure) async {
    setDeparture(departure);

    if (sheetController.currentSheet.value != 'Trip Details') {
      await Get.find<MapController>().tripPath?.setDirection(false);
      await Get.find<MapController>().renderTripPath();
      await Get.find<MapController>().showPolyLine();
    }
    sheetController.pushSheet('Departure Details');

    // if (Get.isRegistered<DepartureDetailsController>()) {
    //   Get.find<DepartureDetailsController>().fetchPattern(true);
    // }
  }

  // Future<void> updateDepartures() async {
  //    if (sheetController.currentSheet.value == 'Departure Details'
  //       && Get.isRegistered<DepartureDetailsController>()) {
  //     await details.value.trip!.updateDepartures();
  //     Get.find<DepartureDetailsController>().fetchPattern(false);
  //     details.refresh();
  //   }
  // }

  /// Sets new stops list & initializes expansion states
  Future<void> setStops(String routeType, int distance) async {
    List<Stop> uniqueStops = await searchUtils.getStops(details.value.markerPos!, routeType, distance);

    details.update((d) => d?.stops = uniqueStops);

    resetStopExpanded();
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

  /// Sets new trip list based on stop and route pair
  Future<void> setTripList() async {
    List<Trip> newTripList = await searchUtils.splitDirection(
        details.value.stop!, details.value.route!);

    details.update((d) => d?.tripList = newTripList);
  }

  void resetDetails() => details.value = SearchDetails();
  void setStop(Stop stop) => details.update((d) => d?.stop = stop);
  void setTrip(Trip trip) => details.update((d) => d?.trip = trip);
  void setDeparture(Departure departure) => details.update((d) => d?.departure = departure);
}