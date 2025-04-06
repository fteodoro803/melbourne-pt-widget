import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api_data.dart';
import '../ptv_api_service.dart';
import '../ptv_info_classes/route_direction_info.dart';
import '../ptv_info_classes/route_info.dart' as pt_route;
import '../ptv_info_classes/route_type_info.dart';
import '../ptv_info_classes/stop_info.dart';
import '../ptv_service.dart';
import '../transport.dart';

class SearchUtils {
  PtvService ptvService = PtvService();

  Future<List<Transport>> splitDirection(Stop stop, pt_route.Route route) async {
    String? routeId = route.id.toString();
    List<RouteDirection> directions = [];
    List<Transport> transportList = [];

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeDirections(routeId);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print(
          "( search_screen.dart -> splitDirection ) -- Null Data response Improper Data");
      return [];
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      int id = direction["direction_id"];
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      RouteDirection newDirection =
      RouteDirection(id: id, name: name, description: description);

      directions.add(newDirection);
    }

    for (var direction in directions) {
      Transport newTransport = Transport.withStopRoute(stop, route, direction);
      newTransport.routeType = RouteType.withId(id: route.type.type.id);
      await newTransport.updateDepartures();
      transportList.add(newTransport);
    }

    return transportList;
  }

  Future<List<Stop>> getStops(LatLng position, String transportType, int distance) async {
    StopRouteLists stopRouteLists;

    if (transportType == "all") {
      stopRouteLists = await ptvService.fetchStopRoutePairs(
        position,
        maxDistance: distance,
        maxResults: 50,
      );
    } else {
      stopRouteLists = await ptvService.fetchStopRoutePairs(
        position,
        routeTypes: transportType,
        maxDistance: distance,
        maxResults: 50,
      );
    }

    Set<String> uniqueStopIDs = {};
    List<Stop> uniqueStops = [];

    List<Stop> stopList = stopRouteLists.stops;
    List<pt_route.Route> routeList = stopRouteLists.routes;

    int stopIndex = 0;

    for (var stop in stopList) {
      if (!uniqueStopIDs.contains(stop.id.toString())) {
        // Create a new stop object to avoid reference issues
        Stop newStop = Stop(
          id: stop.id,
          name: stop.name,
          latitude: stop.latitude,
          longitude: stop.longitude,
          distance: stop.distance,
        );

        newStop.routes = <pt_route.Route>[];
        newStop.routeType = routeList[stopIndex].type;

        uniqueStops.add(newStop);
        uniqueStopIDs.add(stop.id.toString());
      }

      // Find the index of this stop in our uniqueStops list
      int uniqueStopIndex = uniqueStops.indexWhere((s) => s.id == stop.id);
      if (uniqueStopIndex != -1) {
        uniqueStops[uniqueStopIndex].routes!.add(routeList[stopIndex]);
      }

      stopIndex++;
    }

    return uniqueStops;
  }
}