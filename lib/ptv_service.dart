// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/geopath.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_api_service.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StopRouteLists {
  List<Stop> stops;
  List<Route> routes;

  StopRouteLists(this.stops, this.routes);
}

class PtvService {
  Future<List<Departure>> fetchDepartures(String routeType, String stopId,
      String routeId,
      {String? directionId, String? maxResults = "20", String? expands = "All"}) async {
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

      Departure newDeparture = Departure(
          scheduledDepartureUTC: scheduledDepartureUTC,
          estimatedDepartureUTC: estimatedDepartureUTC,
          runRef: runRef);

      // Get Vehicle descriptors per Departure
      var vehicleDescriptors = jsonResponse["runs"]?[runRef]?["vehicle_descriptor"]; // makes vehicleDescriptors null if data for "runs" and/or "runRef" doesn't exist
      if (vehicleDescriptors != null && vehicleDescriptors
          .toString()
          .isNotEmpty) {
        // print("( ptv_service.dart -> fetchDepartures ) -- descriptors for $runRef exists: \n ${jsonResponse["runs"][runRef]["vehicle_descriptor"]}");

        newDeparture.hasLowFloor = vehicleDescriptors["low_floor"];
      }
      else {
        print(
            "( ptv_service.dart -> fetchDepartures() ) -- runs for runRef $runRef is empty )");
      }

      departures.add(newDeparture);
    }

    return departures;
  }

  // void fetchStopRoutePairs(LatLng location, {String routeTypes = "all", int maxResults = 3, int maxDistance = 300}) async {
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

        Route newRoute = Route(
            name: routeName, number: routeNumber, id: routeId, type: routeType);

        stops.add(newStop);
        routes.add(newRoute);
      }
    }

    return StopRouteLists(stops, routes);
  }

  // todo Fetch Stops near a Location

  // Fetch Stops along a Route
  Future<List<Stop>> fetchStopsRoute(Route route, {RouteDirection? direction}) async {
    List<Stop> stopList = [];

    // Fetches stops data via PTV API
    ApiData data;
    if (direction != null) {
      data = await PtvApiService().stopsAlongRoute(
          route.id.toString(), route.type.id.toString(), directionId: direction.id.toString(),
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

  Future<void> fetchRuns(Transport transport) async {
    String expands = "All";
    String? runRef = transport.departures?[0].runRef;
    RouteType? routeType = transport.routeType;
    ApiData data = await PtvApiService().runs(runRef!, routeType!.name, expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    print("(ptv_service.dart -> fetchRuns) -- Fetched Runs:\n$jsonResponse");
  }

  Future<List<Departure>> fetchPattern(Transport transport, Departure departure) async {
    List<Departure> departures = [];
    String expands = "Stop";
    String? runRef = departure.runRef;
    RouteType? routeType = transport.routeType;
    ApiData data = await PtvApiService().patterns(runRef!, routeType!.name, expand: expands);
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

      Departure newDeparture = Departure(
          scheduledDepartureUTC: scheduledDepartureUTC,
          estimatedDepartureUTC: estimatedDepartureUTC,
          runRef: runRef,
          stopId: stopId,
      );

      // Get Stop Name per Departure
      String? stopName = jsonResponse["stops"]?[stopId.toString()]?["stop_name"]; // makes stopName null if data for "runs" and/or "runRef" doesn't exist
      if (stopName != null && stopName.toString().isNotEmpty) {
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
}
