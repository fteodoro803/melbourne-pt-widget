import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/services/ptv/ptv_base_service.dart';

class PtvDepartureService extends PtvBaseService {
  // todo: convert to int for ids
  // todo: change definition to fetchDepartures(Route route, Stop stop, {...})
  Future<List<Departure>> fetchDepartures(String routeType, String stopId, String routeId, {String? directionId, String? maxResults = "3", String? expands = "All"}) async {
    List<Departure> departures = [];

    // 1. Fetches departure data via PTV API
    ApiData data = await apiService.departures(
        routeType, stopId,
        directionId: directionId,
        routeId: routeId,
        maxResults: maxResults,
        expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    // print(" ( ptv_service.dart -> fetchDepartures() ) -- fetched departures response for routeType=$routeType, directionId=$directionId, routeId=$routeId: ${JsonEncoder.withIndent('  ').convert(jsonResponse)} ");

    // Empty JSON Response
    if (jsonResponse == null) {
      handleNullResponse("fetchDepartures");
      return [];
    }

    // 2. Converts departure time response to DateTime object, and adds to departure list
    Map<String, dynamic>? runData = jsonResponse["runs"];
    for (var departure in jsonResponse["departures"]) {
      Departure newDeparture = Departure.fromAPI(departure, runData);
      departures.add(newDeparture);
    }

    return departures;
  }
}