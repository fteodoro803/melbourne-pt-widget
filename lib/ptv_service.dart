// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/database/helpers/directionHelpers.dart';
import 'package:flutter_project/database/helpers/routeHelpers.dart';
import 'package:flutter_project/database/helpers/routeStopsHelpers.dart';
import 'package:flutter_project/database/helpers/routeTypeHelpers.dart';
import 'package:flutter_project/database/helpers/stopHelpers.dart';
import 'package:flutter_project/database/helpers/stopRouteTypesHelpers.dart';
import 'package:flutter_project/geopath.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'database/database.dart' as db;
import 'package:get/get.dart';

class StopRouteLists {
  List<Stop> stops;
  List<Route> routes;

  StopRouteLists(this.stops, this.routes);
}

/// Handles calling the PTV API, converting to domain models, and storing to database

class PtvService {

// Departure Functions
  // todo: use fromApi constructor
  Future<List<Departure>> fetchDepartures(String routeType, String stopId, String routeId, {String? directionId, String? maxResults = "3", String? expands = "All"}) async {
    List<Departure> departures = [];

    // Fetches departure data via PTV API
    ApiData data = await PtvApiService().departures(
        routeType, stopId,
        directionId: directionId,
        routeId: routeId,
        maxResults: maxResults,
        expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    // print(" ( ptv_service.dart -> fetchDepartures() ) -- fetched departures response for routeType=$routeType, directionId=$directionId, routeId=$routeId: ${JsonEncoder.withIndent('  ').convert(jsonResponse)} ");

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "( ptv_service.dart -> fetchDepartures ) -- Null data response, Improper Location Data");
      return departures;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var departure in jsonResponse["departures"]) {
      DateTime? scheduledDepartureUTC = departure["scheduled_departure_utc"] !=
          null ? DateTime.parse(departure["scheduled_departure_utc"]) : null;
      DateTime? estimatedDepartureUTC = departure["estimated_departure_utc"] !=
          null ? DateTime.parse(departure["estimated_departure_utc"]) : null;
      String? runRef = departure["run_ref"]?.toString();
      int? stopId = departure["stop_id"];

      // Get Vehicle descriptors per Departure
      var vehicleDescriptors = jsonResponse["runs"]?[runRef]?["vehicle_descriptor"]; // makes vehicleDescriptors null if data for "runs" and/or "runRef" doesn't exist
      bool? hasLowFloor;
      bool? hasAirConditioning;
      if (vehicleDescriptors != null && vehicleDescriptors
          .toString()
          .isNotEmpty) {
        // print("( ptv_service.dart -> fetchDepartures ) -- descriptors for $runRef exists: \n ${jsonResponse["runs"][runRef]["vehicle_descriptor"]}");

        hasLowFloor = vehicleDescriptors["low_floor"];
        hasAirConditioning = vehicleDescriptors["air_conditioned"];
      }
      else {
        print(
            "( ptv_service.dart -> fetchDepartures() ) -- runs for runRef $runRef is empty )");
      }

      Departure newDeparture = Departure(
        scheduledDepartureUTC: scheduledDepartureUTC,
        estimatedDepartureUTC: estimatedDepartureUTC,
        runRef: runRef,
        stopId: stopId,
        hasAirConditioning: hasAirConditioning,
        hasLowFloor: hasLowFloor,
      );

      departures.add(newDeparture);
    }

    return departures;
  }

// Direction Functions
  // todo: add to database
  Future<List<RouteDirection>> fetchDirections(int routeId) async {
    List<RouteDirection> directionList = [];

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeDirections(routeId.toString());
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("( ptv_service.dart -> fetchDirections ) -- Null response");
      return [];
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      RouteDirection newDirection = RouteDirection.fromApi(direction);
      directionList.add(newDirection);

      // Adding to database
      await Get.find<db.AppDatabase>().addDirection(newDirection.id, newDirection.name, newDirection.description);
    }

    return directionList;
  }

// GeoPath Functions
  // todo: add to database
  Future<List<LatLng>> fetchGeoPath(Route route) async {
    List<LatLng> pathList = [];

    // Fetches stops data via PTV API
    ApiData data = await PtvApiService().stopsAlongRoute(
        route.id.toString(), route.type.id.toString(), geoPath: true);
    Map<String, dynamic>? jsonResponse = data.response;

    // print(" (ptv_service.dart -> fetchGeoPath) -- fetched Geopath for route ${route.id}:\n${JsonEncoder.withIndent('  ').convert(jsonResponse)} ");

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "(ptv_service.dart -> fetchGeoPath) -- Null data response, Improper Location Data");
      return pathList;
    }

    // Adding GeoPath to List if GeoPath isn't empty
    List<dynamic> geopath = jsonResponse["geopath"];
    if (geopath.isNotEmpty) {
      var paths = jsonResponse["geopath"][0]["paths"];
      pathList = convertPolylineToLatLng(paths);
    }

    // convertPolylineToCsv(paths);     // test save to CSV, for rendering on https://kepler.gl/demo

    return pathList;
  }

// Pattern Functions
  // todo: use fromApi constructor
  // todo: add to database
  Future<List<Departure>> fetchPattern(Transport transport, Departure departure) async {
    List<Departure> departures = [];

    // if (departure == null) {
    //   return [];
    // }

    String expands = "Stop";
    String? runRef = departure.runRef;
    RouteType? routeType = transport.routeType;
    ApiData data = await PtvApiService().patterns(
        runRef!, routeType!.name, expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "( ptv_service.dart -> fetchDepartures ) -- Null data response, Improper Location Data");
      return departures;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var departure in jsonResponse["departures"]) {
      DateTime? scheduledDepartureUTC = departure["scheduled_departure_utc"] !=
          null ? DateTime.parse(departure["scheduled_departure_utc"]) : null;
      DateTime? estimatedDepartureUTC = departure["estimated_departure_utc"] !=
          null ? DateTime.parse(departure["estimated_departure_utc"]) : null;
      String? runRef = departure["run_ref"]?.toString();
      int? stopId = departure["stop_id"];
      var vehicleDescriptors = jsonResponse["runs"]?[runRef]?["vehicle_descriptor"]; // makes vehicleDescriptors null if data for "runs" and/or "runRef" doesn't exist
      bool? hasLowFloor;
      bool? hasAirConditioning;
      if (vehicleDescriptors != null && vehicleDescriptors
          .toString()
          .isNotEmpty) {
        hasLowFloor = vehicleDescriptors["low_floor"];
        hasAirConditioning = vehicleDescriptors["air_conditioned"];
      }

      Departure newDeparture = Departure(
          scheduledDepartureUTC: scheduledDepartureUTC,
          estimatedDepartureUTC: estimatedDepartureUTC,
          runRef: runRef,
          stopId: stopId,
          hasLowFloor: hasLowFloor,
          hasAirConditioning: hasAirConditioning
      );

      // Get Stop Name per Departure
      String? stopName = jsonResponse["stops"]?[stopId
          .toString()]?["stop_name"]; // makes stopName null if data for "runs" and/or "runRef" doesn't exist
      if (stopName != null && stopName
          .toString()
          .isNotEmpty) {
        // print("( ptv_service.dart -> fetchDepartures ) -- descriptors for $runRef exists: \n ${jsonResponse["runs"][runRef]["vehicle_descriptor"]}");

        newDeparture.stopName = stopName;
      }
      else {
        print(
            "( ptv_service.dart -> fetchPattern() ) -- patterns for runRef $runRef is empty )");
      }

      departures.add(newDeparture);
    }

    // String prettyJson = JsonEncoder.withIndent('  ').convert(jsonResponse);
    // print("(ptv_service.dart -> fetchPattern) -- Fetched Pattern:\n$prettyJson");
    return departures;
  }

// Route Functions
  /// Fetches all routes offered by PTV, and saves them to the database
  Future<List<Route>> fetchRoutes({String? routeTypes}) async {
    List<Route> routeList = [];

    // Fetches stop data via PTV API
    ApiData data = await PtvApiService().routes(routeTypes: routeTypes);
    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print("(ptv_service.dart -> fetchRoutes) -- Null data response");
      return [];
    }

    // Creates new routes, and adds them to return list and database
    for (var route in jsonResponse["routes"]) {
      Route newRoute = Route.fromApi(route);
      routeList.add(newRoute);

      // Add to Database
      await Get.find<db.AppDatabase>().addRoute(newRoute.id, newRoute.name, newRoute.number, newRoute.type.id, newRoute.gtfsId, newRoute.status);
    }

    return routeList;
  }

  /// Fetches routes from database, by search name.
  Future<List<Route>> searchRoutes({String? query, RouteType? routeType}) async {
    final dbRouteList = await Get.find<db.AppDatabase>().getRoutes(search: query, routeType: routeType?.id);
    List<Route> domainRouteList = dbRouteList.map(Route.fromDb).toList();
    return domainRouteList;
  }

  /// Fetches routes according to a stop, from the database.
  /// Maps the databases' routes to domain's route
  // todo: change this to getRoutesFromStop, or something like that. Fetch is reserved for functions with API calls
  Future<List<Route>> fetchRoutesFromStop(int stopId) async {
    final dbRoutes = await Get.find<db.AppDatabase>().getRoutesFromStop(stopId);

    // Convert Route's database model to domain model
    List<Route> routeList = dbRoutes.map(Route.fromDb).toList();

    return routeList;
  }

// RouteType Functions
  /// Fetches route types offered by PTV, and saves them to the database
  Future<List<String>> fetchRouteTypes() async {
    List<String> routeTypes = [];

    ApiData data = await PtvApiService().routeTypes();
    Map<String, dynamic>? jsonResponse = data.response;

    // Early exit: Empty response
    if (data.response == null) {
      print("( ptv_service.dart -> fetchRouteTypes ) -- Null response");
      return [];
    }

    // Populating RouteTypes list
    for (var entry in jsonResponse!["route_types"]) {
      int id = entry["route_type"];
      RouteType newRouteType = RouteType.fromId(id);
      routeTypes.add(newRouteType.name);

      // Add to database
      Get.find<db.AppDatabase>().addRouteType(newRouteType.id, newRouteType.name);
    }

    return routeTypes;
  }

// Runs Functions
  Future<void> fetchRuns(Transport transport) async {
    String expands = "All";
    String? runRef = transport.departures?[0].runRef;
    RouteType? routeType = transport.routeType;
    ApiData data = await PtvApiService().runs(
        runRef!, routeType!.name, expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    print("(ptv_service.dart -> fetchRuns) -- Fetched Runs:\n$jsonResponse");
  }

// Stop Functions
  /// Fetch Stops near a Location and saves them to the database.
  /// This function also creates a link between the stop and route it's on.
  Future<List<Stop>> fetchStopsLocation(String location, {int? routeType, int? maxDistance}) async {
    List<Stop> stopList = [];
    List<Future> futures = [];    // holds all Futures for database async operations

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().stopsLocation(
        location, routeTypes: routeType?.toString(), maxDistance: maxDistance?.toString());
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("( ptv_service.dart -> fetchStopsLocation ) -- null response");
      return [];
    }

    // Populating stops list and adding them to Database
    for (var stop in jsonResponse!["stops"]) {
      Stop newStop = Stop.fromApi(stop);
      stopList.add(newStop);
      futures.add(Get.find<db.AppDatabase>().addStop(newStop.id, newStop.name, newStop.latitude!, newStop.longitude!));

      // Adds route-stop relationship to database
      int selectedRouteType = stop["route_type"];
      for (var route in stop["routes"]) {
        int routeId = route["route_id"];
        int currRouteTypeId = route["route_type"];
        futures.add(Get.find<db.AppDatabase>().addStopRouteType(newStop.id, currRouteTypeId));

        if (route["route_type"] != selectedRouteType) {
          continue;
        }

        futures.add(Get.find<db.AppDatabase>().addRouteStop(routeId, newStop.id));
      }
    }

    // Wait for all Futures to complete
    await Future.wait(futures);

    return stopList;
  }

  /// Fetch Stops along a Route and saves them to the database.
  /// Also saves the link between the route and its stops.
  Future<List<Stop>> fetchStopsRoute(Route route, {RouteDirection? direction}) async {
    List<Stop> stopList = [];

    // Fetches stops data via PTV API
    ApiData data;
    if (direction != null) {
      data = await PtvApiService().stopsAlongRoute(
          route.id.toString(), route.type.id.toString(),
          directionId: direction.id.toString(),
          geoPath: true);
    }
    else {
      // Auto-select a direction to get stop sequence data
      // Stop sequence is only available from the api if a direction is given, but the direction doesn't seem to make a difference
      List<RouteDirection> directions = await fetchDirections(route.id);

      if (directions.isNotEmpty) {
        data = await PtvApiService().stopsAlongRoute(route.id.toString(), route.type.id.toString(), directionId: directions[0].id.toString(), geoPath: true);
      }
      else {
        data = await PtvApiService().stopsAlongRoute(route.id.toString(), route.type.id.toString(), geoPath: true);
      }
    }

    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "(ptv_service.dart -> fetchStopsAlongDirection) -- Null data response");
      return stopList;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var stop in jsonResponse["stops"]) {
      int id = stop["stop_id"];
      String name = stop["stop_name"];
      double latitude = stop["stop_latitude"];
      double longitude = stop["stop_longitude"];
      String suburb = stop["stop_suburb"];
      int stopSequence = stop["stop_sequence"];

      Stop newStop = Stop(
          id: id,
          name: name,
          latitude: latitude,
          longitude: longitude,
          suburb: suburb,
          stopSequence: stopSequence,
      );
      stopList.add(newStop);

      // Add to database
      Get.find<db.AppDatabase>().addStop(id, name, latitude, longitude, sequence: stopSequence);
      Get.find<db.AppDatabase>().addRouteStop(route.id, id);

    }

    // todo: convert this entire function into the following:
    // 1. make api call, if data doesn't exist in database
    // 2. convert api response to domain models, via factory constructor
    // 3. convert domain model to companions? - think about making a toCompanion first
    // 4. use helper for single/batch inserts

    // // Convert domain models to companion
    // final stopCompanions = stopList.map((stop) => stop.toCompanion()).toList();

    // // Use helper to batch insert
    // await Get.find<db.AppDatabase>().batchInsertStops(stopCompanions: stopCompanions, routeId: route.id);

    return stopList;
  }

  Future<StopRouteLists> fetchStopRoutePairs(LatLng location, {String routeTypes = "all", int maxResults = 3, int maxDistance = 300}) async {
    List<Stop> stops = [];
    List<Route> routes = [];

    String locationString = "${location.latitude},${location.longitude}";

    // Conversion of RouteTypes to proper String
    String routeTypeString = "";
    if (routeTypes == "all") {
      routeTypeString = "";
    }
    else {
      routeTypeString = routeTypes;
    }

    // Fetches stop data via PTV API
    ApiData data = await PtvApiService().stopsLocation(
      locationString,
      maxResults: maxResults.toString(),
      maxDistance: maxDistance.toString(),
      routeTypes: routeTypeString,
    );
    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "( ptv_service.dart -> fetchDepartures ) -- Null data response, Improper Location Data");
      return StopRouteLists([], []);
    }

    // Populating Stops List
    for (var stop in jsonResponse["stops"]) {
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
        Stop newStop = Stop(id: stopId,
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
        String status = "TEMPORARY"; // todo: fix this, or the logic of the class

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