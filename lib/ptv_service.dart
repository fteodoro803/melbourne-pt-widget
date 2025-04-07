// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/database/helpers/routeTypeHelpers.dart';
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
  Future<List<RouteDirection>> fetchDirections(int routeId) async {
    List<RouteDirection> directionList = [];

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeDirections(routeId.toString());
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("( ptv_service.dart -> fetchDirections ) -- Null response");
      return directionList;
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      // if (direction["route_id"] != widget.userSelections.stop?.route.id) {continue;}

      int id = direction["direction_id"];
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];

      RouteDirection newDirection =
      RouteDirection(id: id, name: name, description: description);

      directionList.add(newDirection);
    }

    return directionList;
  }

// GeoPath Functions
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
  Future<List<Departure>> fetchPattern(Transport transport, Departure departure) async {
    List<Departure> departures = [];
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
  Future<List<Route>> fetchRoutes({String? routeTypes}) async {
    List<Route> routeList = [];

    // Fetches stop data via PTV API
    ApiData data = await PtvApiService().routes(routeTypes: routeTypes);
    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "(ptv_service.dart -> fetchRoutes) -- Null data response, Improper Location Data");
      return routeList;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var route in jsonResponse["routes"]) {
      int id = route["route_id"];
      String name = route["route_name"];
      String number = route["route_number"];
      RouteType type = RouteType.fromId(route["route_type"]);
      String status = route["route_service_status"]["description"];

      Route newRoute = Route(id: id,
          name: name,
          number: number,
          type: type,
          status: status);
      routeList.add(newRoute);
    }

    return routeList;
  }

// RouteType Functions
  /// Fetches route types offered by PTV, and saves them to the database
  Future<List<String>> fetchRouteTypes() async {
    List<String> routeTypes = [];

    ApiData data = await PtvApiService().routeTypes();
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("( ptv_service.dart -> fetchRouteTypes ) -- null data response");
      return routeTypes;
    }

    // Populating RouteTypes List
    for (var entry in jsonResponse!["route_types"]) {
      int id = entry["route_type"];
      String name = entry["route_type_name"];
      routeTypes.add(name);

      // Add to database
      Get.find<db.AppDatabase>().addRouteType(id, name);
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
  // todo Fetch Stops near a Location

  // Fetch Stops along a Route
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
      data = await PtvApiService().stopsAlongRoute(
          route.id.toString(), route.type.id.toString(), geoPath: true);
    }
    Map<String, dynamic>? jsonResponse = data.response;

    // print(" (ptv_service.dart -> fetchStopsAlongDirection) -- fetched stops along direction:\n${JsonEncoder.withIndent('  ').convert(jsonResponse)} ");

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "(ptv_service.dart -> fetchStopsAlongDirection) -- Null data response, Improper Location Data");
      return stopList;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var stop in jsonResponse["stops"]) {
      int id = stop["stop_id"];
      String name = stop["stop_name"];
      double latitude = stop["stop_latitude"];
      double longitude = stop["stop_longitude"];

      Stop newStop = Stop(
          id: id, name: name, latitude: latitude, longitude: longitude);
      stopList.add(newStop);
    }

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
    ApiData data = await PtvApiService().stops(
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
        String status = "TEMPORARY"; // todo: fix this, or the logic of the class

        Route newRoute = Route(
            name: routeName,
            number: routeNumber,
            id: routeId,
            type: routeType,
            status: status);

        stops.add(newStop);
        routes.add(newRoute);
      }
    }

    return StopRouteLists(stops, routes);
  }

}