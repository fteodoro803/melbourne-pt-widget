// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/ptvInfoClasses/DepartureInfo.dart';
import 'package:flutter_project/ptv_api_service.dart';

class DepartureService {
  Future<List<Departure>> fetchDepartures(String routeType, String stopId,
      String directionId, String routeId,
      {String maxResults = "3", String expands = "All"}) async {
    List<Departure> departures = [];

    Data data = await PtvApiService().departures(
        routeType, stopId, directionId: directionId,
        routeId: routeId,
        maxResults: maxResults,
        expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    if (jsonResponse == null) {
      print("NULL DATA RESPONSE --> Improper Location Data");
      return departures;
    }

    for (var departure in jsonResponse["departures"]) {
      DateTime? scheduledDepartureUTC = departure["scheduled_departure_utc"] !=
          null ? DateTime.parse(departure["scheduled_departure_utc"]) : null;
      DateTime? estimatedDepartureUTC = departure["estimated_departure_utc"] !=
          null ? DateTime.parse(departure["estimated_departure_utc"]) : null;

      departures.add(Departure(scheduledDepartureUTC: scheduledDepartureUTC,
          estimatedDepartureUTC: estimatedDepartureUTC));
    }

    return departures;
  }

  // update Departure function
}