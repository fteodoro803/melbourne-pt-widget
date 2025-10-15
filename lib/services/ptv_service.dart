// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/domain/disruption.dart';
import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/services/ptv/ptv_departure_service.dart';
import 'package:flutter_project/services/ptv/ptv_route_service.dart';
import 'package:flutter_project/services/ptv/ptv_route_type_service.dart';
import 'package:flutter_project/services/ptv/ptv_stop_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_project/services/ptv/ptv_direction_service.dart';
import 'package:flutter_project/services/ptv/ptv_trip_service.dart';

class StopRouteLists {
  List<Stop> stops;
  List<Route> routes;

  StopRouteLists(this.stops, this.routes);
}

/// Handles calling the PTV API, converting to domain models, and storing to database

class PtvService {
  final PtvDepartureService departures = PtvDepartureService();
  final PtvDirectionService directions = PtvDirectionService();
  final PtvRouteService routes = PtvRouteService();
  final PtvRouteTypeService routeTypes = PtvRouteTypeService();
  final PtvStopService stops = PtvStopService();
  final PtvTripService trips = PtvTripService();

  /// Adds PTV Route and RouteType data to database
  Future<void> initialise() async {
    await routeTypes.fetchRouteTypes();
    await routes.fetchRoutes();
  }

// Disruption Functions
  /// Fetches disruptions for a given route.
  Future<List<Disruption>> fetchDisruptions(Route route) async {
    List<Disruption> disruptions = [];

    // Fetches disruption data via PTV API
    var data = await PtvApiService().disruptions(route.id.toString());

    // Empty JSON Response
    if (data == null) {
      print("( ptv_service.dart -> fetchDisruptions ) -- Null data response");
      return [];
    }

    String routeType = "";
    if (route.type == RouteType.train) {
      // todo: add the other route types (vLine, nightBus)
      routeType = "metro_train";
    } else if (route.type == RouteType.tram) {
      routeType = "metro_tram";
    } else if (route.type == RouteType.bus) {
      routeType = "metro_bus";
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var disruption in data["disruptions"][routeType]) {
      Disruption newDisruption = Disruption.fromApi(data: disruption);
      disruptions.add(newDisruption);
    }

    return disruptions;
  }

// Pattern Functions
  // todo: use fromApi constructor
  // todo: add to database
  Future<List<Departure>> fetchPattern(Trip trip, Departure departure) async {
    List<Departure> departures = [];

    // if (departure == null) {
    //   return [];
    // }

    String expands = "Stop";
    String? runRef = departure.runRef;
    RouteType? routeType = trip.route?.type;
    var data = await PtvApiService()
        .patterns(runRef!, routeType!.name, expand: expands);

    // Empty JSON Response
    if (data == null) {
      print(
          "( ptv_service.dart -> fetchDepartures ) -- Null data response, Improper Location Data");
      return departures;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var departure in data["departures"]) {
      DateTime? scheduledDepartureUTC =
          departure["scheduled_departure_utc"] != null
              ? DateTime.parse(departure["scheduled_departure_utc"])
              : null;
      DateTime? estimatedDepartureUTC =
          departure["estimated_departure_utc"] != null
              ? DateTime.parse(departure["estimated_departure_utc"])
              : null;
      String? runRef = departure["run_ref"]?.toString();
      int? stopId = departure["stop_id"];
      String? platformNumber = departure["platform_number"];
      var vehicleDescriptors = data["runs"]?[runRef]?[
          "vehicle_descriptor"]; // makes vehicleDescriptors null if data for "runs" and/or "runRef" doesn't exist
      bool? hasLowFloor;
      bool? hasAirConditioning;
      if (vehicleDescriptors != null &&
          vehicleDescriptors.toString().isNotEmpty) {
        hasLowFloor = vehicleDescriptors["low_floor"];
        hasAirConditioning = vehicleDescriptors["air_conditioned"];
      }

      Departure newDeparture = Departure(
          scheduledDepartureUTC: scheduledDepartureUTC,
          estimatedDepartureUTC: estimatedDepartureUTC,
          runRef: runRef,
          stopId: stopId,
          hasLowFloor: hasLowFloor,
          hasAirConditioning: hasAirConditioning,
          platformNumber: platformNumber);

      // Get Stop Name per Departure
      String? stopName = data["stops"]?[stopId.toString()]?[
          "stop_name"]; // makes stopName null if data for "runs" and/or "runRef" doesn't exist
      if (stopName != null && stopName.toString().isNotEmpty) {
        // print("( ptv_service.dart -> fetchDepartures ) -- descriptors for $runRef exists: \n ${jsonResponse["runs"][runRef]["vehicle_descriptor"]}");

        newDeparture.stopName = stopName;
      } else {
        print(
            "( ptv_service.dart -> fetchPattern() ) -- patterns for runRef $runRef is empty )");
      }

      departures.add(newDeparture);
    }

    // String prettyJson = JsonEncoder.withIndent('  ').convert(jsonResponse);
    // print("(ptv_service.dart -> fetchPattern) -- Fetched Pattern:\n$prettyJson");
    return departures;
  }

// Runs Functions
  Future<void> fetchRuns(Trip trip) async {
    String expands = "All";
    String? runRef = trip.departures?[0].runRef;
    RouteType? routeType = trip.route?.type;
    var data =
        await PtvApiService().runs(runRef!, routeType!.name, expand: expands);

    print("(ptv_service.dart -> fetchRuns) -- Fetched Runs:\n$data");
  }

  Future<StopRouteLists> fetchStopRoutePairs(LatLng location,
      {String routeTypes = "all",
      int maxResults = 3,
      int maxDistance = 300}) async {
    List<Stop> stops = [];
    List<Route> routes = [];

    String locationString = "${location.latitude},${location.longitude}";

    // Conversion of RouteTypes to proper String
    String routeTypeString = "";
    if (routeTypes == "all") {
      routeTypeString = "";
    } else {
      routeTypeString = routeTypes;
    }

    // Fetches stop data via PTV API
    var data = await PtvApiService().stopsLocation(
      locationString,
      maxResults: maxResults.toString(),
      maxDistance: maxDistance.toString(),
      routeTypes: routeTypeString,
    );

    // Empty JSON Response
    if (data == null) {
      print(
          "( ptv_service.dart -> fetchDepartures ) -- Null data response, Improper Location Data");
      return StopRouteLists([], []);
    }

    // Populating Stops List
    for (var stop in data["stops"]) {
      for (var route in stop["routes"]) {
        // // Selecting based on RouteType
        // if (route["route_type"].toString() != routeTypes) {
        //   continue;
        // }

        int stopId = stop["stop_id"];
        String stopName = stop["stop_name"];
        double latitude = stop["stop_latitude"];
        double longitude = stop["stop_longitude"];
        double? distance = stop["stop_distance"];
        Stop newStop = Stop(
            id: stopId,
            name: stopName,
            latitude: latitude,
            longitude: longitude,
            distance: distance);

        String routeName = route["route_name"];
        String routeNumber = route["route_number"].toString();
        int routeId = route["route_id"];
        int routeTypeId = route["route_type"];
        RouteType routeType = RouteType.fromId(routeTypeId);
        String gtfsId = "TEMPORARY"; // todo: fix this
        String status =
            "TEMPORARY"; // todo: fix this, or the logic of the class

        Route newRoute = Route(
            name: routeName,
            number: routeNumber,
            id: routeId,
            type: routeType,
            gtfsId: gtfsId,
            status: status);

        stops.add(newStop);
        routes.add(newRoute);
      }
    }

    return StopRouteLists(stops, routes);
  }
}
