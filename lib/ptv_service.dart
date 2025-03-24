// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_api_service.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StopRouteLists {
  List<Stop> stops;
  List<Route> routes;

  StopRouteLists(this.stops, this.routes);
}

class PtvService {
  Future<List<Departure>> fetchDepartures(String routeType, String stopId, String routeId, {String? directionId, String maxResults = "3", String expands = "All"}) async {
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
      print("( ptv_service.dart -> fetchDepartures ) -- Null data response, Improper Location Data");
      return departures;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var departure in jsonResponse["departures"]) {
      DateTime? scheduledDepartureUTC = departure["scheduled_departure_utc"] !=
          null ? DateTime.parse(departure["scheduled_departure_utc"]) : null;
      DateTime? estimatedDepartureUTC = departure["estimated_departure_utc"] !=
          null ? DateTime.parse(departure["estimated_departure_utc"]) : null;
      String? runId = departure["run_id"]?.toString();
      String? runRef = departure["run_ref"]?.toString();

      Departure newDeparture = Departure(scheduledDepartureUTC: scheduledDepartureUTC,
          estimatedDepartureUTC: estimatedDepartureUTC, runId: runId, runRef: runRef);

      // Get Vehicle descriptors per Departure
      var vehicleDescriptors = jsonResponse["runs"]?[runRef]?["vehicle_descriptor"];    // makes vehicleDescriptors null if data for "runs" and/or "runRef" doesn't exist
      if (vehicleDescriptors != null && vehicleDescriptors.toString().isNotEmpty) {
        // print("( ptv_service.dart -> fetchDepartures ) -- descriptors for $runRef exists: \n ${jsonResponse["runs"][runRef]["vehicle_descriptor"]}");

        newDeparture.hasLowFloor = vehicleDescriptors["low_floor"];
      }
      else { print("( ptv_service.dart -> fetchDepartures() ) -- runs for runId $runId is empty )");}

      departures.add(newDeparture);
    }

    return departures;
  }

  // void fetchStopRoutePairs(LatLng location, {String routeTypes = "all", int maxResults = 3, int maxDistance = 300}) async {
  Future<StopRouteLists> fetchStopRoutePairs(LatLng location, {String routeTypes = "all", int maxResults = 3, int maxDistance = 300}) async {
    List<Stop> stops = [];
    List<Route> routes = [];

    String locationString = "${location.latitude},${location.longitude}";

    // Fetches stop data via PTV API
    ApiData data = await PtvApiService().stops(
      locationString,
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

        String stopId = stop["stop_id"].toString();
        String stopName = stop["stop_name"];
        Stop newStop = Stop(id: stopId, name: stopName);

        String routeName = route["route_name"];
        String routeNumber = route["route_number"].toString();
        String routeId = route["route_id"].toString();
        Route newRoute = Route(
            name: routeName, number: routeNumber, id: routeId);


        // Gets the Colour of Route
        String routeType = stop["route_type"].toString();
        // newRoute.getRouteColour(widget.arguments.transport.routeType!.name);      // expects something like, tram, bus, etc

        stops.add(newStop);
        routes.add(newRoute);
      }
    }

    return StopRouteLists(stops, routes);
  }
}