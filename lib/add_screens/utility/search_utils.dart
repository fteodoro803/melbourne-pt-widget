import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/domain/route_direction_info.dart';
import 'package:flutter_project/domain/route_info.dart' as pt_route;
import 'package:flutter_project/domain/route_type_info.dart';
import 'package:flutter_project/domain/stop_info.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/domain/trip.dart';

class UniqueStop {
  final String id;
  final RouteType type;

  UniqueStop(this.id, this.type);

  // Override == operator and hashCode to ensure uniqueness by both first and second elements.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UniqueStop && other.id == id && other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => '($id, $type)';
}

class SuburbStops {
  final String suburb;
  List<Stop> stops;
  bool isExpanded = true;

  SuburbStops({
    required this.suburb,
    required this.stops
  });
}

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
      newTransport.routeType = RouteType.fromId(route.type.id);
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

    List<Stop> uniqueStops = [];
    Set<UniqueStop> uniqueStopsSet= {};

    List<Stop> stopList = stopRouteLists.stops;
    List<pt_route.Route> routeList = stopRouteLists.routes;

    int stopIndex = 0;

    for (var stop in stopList) {
    RouteType routeType = routeList[stopIndex].type;

    if (!uniqueStopsSet.contains(UniqueStop(stop.id.toString(), routeType))) {
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

      uniqueStopsSet.add(UniqueStop(stop.id.toString(), routeType));
    }

    // Find the index of this stop in our uniqueStops list
    int uniqueStopIndex = uniqueStops.indexWhere((s) => s.id == stop.id && s.routeType == routeType);
      if (uniqueStopIndex != -1 &&
          !uniqueStops[uniqueStopIndex].routes!.any((route) => route.id == routeList[stopIndex].id)) {
        uniqueStops[uniqueStopIndex].routes!.add(routeList[stopIndex]);
      }

    stopIndex++;
    }

    return uniqueStops;
  }

  Future<List<RouteDirection>> getRouteDirections(int routeId) async {
    return await ptvService.fetchDirections(routeId);
  }

  Future<List<Stop>> getStopsAlongRoute(List<RouteDirection> directions, pt_route.Route route) async {
    List<Stop> stops = [];
    if (directions.isNotEmpty) {
      stops = await ptvService.fetchStopsRoute(route, direction: directions[0]);
      stops = stops.where((s) => s.stopSequence != 0).toList();
    }
    else {
      stops = await ptvService.fetchStopsRoute(route);
    }

    return stops;
  }

  Future<List<SuburbStops>> getSuburbStops(List<Stop> stopsAlongRoute, pt_route.Route route) async {

    List<SuburbStops> suburbStopsList = [];
    String? previousSuburb;
    List<Stop> stopsInSuburb = [];
    String? currentSuburb;

    for (var stop in stopsAlongRoute) {
      currentSuburb = stop.suburb!;

      Stop newStop = Stop(
        id: stop.id,
        name: stop.name,
        latitude: stop.latitude,
        longitude: stop.longitude,
        distance: stop.distance,
        stopSequence: stop.stopSequence,
        suburb: stop.suburb,
      );

      if (previousSuburb == null || currentSuburb == previousSuburb) {
        stopsInSuburb.add(newStop);
      }
      else {
        suburbStopsList.add(SuburbStops(suburb: previousSuburb, stops: List<Stop>.from(stopsInSuburb)));
        stopsInSuburb = [newStop];
      }

      previousSuburb = currentSuburb;
    }
    suburbStopsList.add(SuburbStops(suburb: previousSuburb!, stops: stopsInSuburb));

    return suburbStopsList;
  }
}