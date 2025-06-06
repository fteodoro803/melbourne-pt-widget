import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart' as pt_route;
import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/services/ptv_service.dart';
import 'package:flutter_project/domain/trip.dart';

class UniqueStop {
  final String id;
  final RouteType type;

  UniqueStop(this.id, this.type);

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

  SuburbStops({
    required this.suburb,
    required this.stops
  });
}

class SearchUtils {
  PtvService ptvService = PtvService();

  /// Returns all trips in all directions a given route travels from a stop
  Future<List<Trip>> splitDirection(Stop stop, pt_route.Route route) async {
    String? routeId = route.id.toString();
    List<Direction> directions = [];
    List<Trip> transportList = [];

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().directions(routeId);
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
      Direction newDirection =
      Direction(id: id, name: name, description: description);

      directions.add(newDirection);
    }

    for (var direction in directions) {
      Trip newTransport = Trip.withStopRoute(stop, route, direction);
      // newTransport.routeType = RouteType.fromId(route.type.id);     // no need for this, routeType is already set when a route is made
      await newTransport.updateDepartures(departureCount: 2);
      await Future.delayed(Duration(milliseconds: 100));
      if (newTransport.departures != null && newTransport.departures!.isNotEmpty) {
        transportList.add(newTransport);
      }
    }

    return transportList;
  }

  /// Finds all stops and routes of a given transport type at a given distance from a position
  /// Separates stops by route type and prevents duplicates
  Future<List<Stop>> getUniqueStops(LatLng position, String transportType, int distance) async {
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

  /// Finds the sequence of stops along a given route
  /// Removes stops that are no longer active
  Future<List<Stop>> getStopsAlongRoute(List<Direction> directions, pt_route.Route route) async {
    List<Stop> stops = [];
    if (directions.isNotEmpty) {
      stops = await ptvService.stops.fetchStopsByRoute(route, direction: directions[0]);
      stops = stops.where((s) => s.stopSequence != 0).toList();
    }
    else {
      stops = await ptvService.stops.fetchStopsByRoute(route);
    }

    return stops;
  }

  /// Takes a list of stops along a route and groups them based on suburb
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

  /// Handles adding/remove transport from favourites
  Future<void> handleSave(Trip transport) async {
    bool isSaved = await ptvService.trips.isTripSaved(transport);
    if (!isSaved) {
      await ptvService.trips.saveTrip(transport);  // Add transport to saved list
    } else {
      await ptvService.trips.deleteTrip(transport.uniqueID!);  // Remove transport from saved list
    }
  }

  static void renderSnackBar(BuildContext context, bool isSaved) {
    floatingSnackBar(
      message: isSaved ? 'Added to Saved Trips.' : 'Removed from Saved Trips.',
      context: context,
      textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      duration: const Duration(milliseconds: 2000),
      backgroundColor: isSaved ? Color(0xFF4E754F) : Color(0xFF7C291F),
    );
  }

  /// Finds the stops along a route and the directions for a route
  Future<pt_route.Route> initializeRoute(pt_route.Route route) async {
    List<Direction> directions = await ptvService.directions.fetchDirections(route.id);
    List<Stop> stopsAlongRoute = await getStopsAlongRoute(directions, route);
    pt_route.Route newRoute = route;
    newRoute.directions = directions;
    newRoute.stopsAlongRoute = stopsAlongRoute;

    return newRoute;
  }
}