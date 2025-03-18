// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_api_service.dart';

class DepartureService {
  Future<List<Departure>> fetchDepartures(String routeType, String stopId,
      String directionId, String routeId,
      {String maxResults = "3", String expands = "All"}) async {
    List<Departure> departures = [];

    // Fetches departure data via PTV API
    Data data = await PtvApiService().departures(
        routeType, stopId, directionId: directionId,
        routeId: routeId,
        maxResults: maxResults,
        expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    // print(" ( departure_service.dart -> fetchDepartures() ) -- fetched departures response: ${JsonEncoder.withIndent('  ').convert(jsonResponse)} ");

    // Empty JSON Response
    if (jsonResponse == null) {
      print("NULL DATA RESPONSE --> Improper Location Data");
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
        // print("( departure_service.dart -> fetchDepartures ) -- descriptors for $runRef exists: \n ${jsonResponse["runs"][runRef]["vehicle_descriptor"]}");

        newDeparture.hasLowFloor = vehicleDescriptors["low_floor"];
      }
      else { print("( departure_service.dart -> fetchDepartures() ) -- runs for runId $runId is empty )");}

      departures.add(newDeparture);
    }

    return departures;
  }
}