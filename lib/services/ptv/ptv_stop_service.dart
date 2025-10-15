import 'package:flutter_project/database/helpers/link_route_stops_helpers.dart';
import 'package:flutter_project/database/helpers/link_stop_directions_helpers.dart';
import 'package:flutter_project/database/helpers/link_stop_route_types_helpers.dart';
import 'package:flutter_project/database/helpers/stop_helpers.dart';
import 'package:flutter_project/domain/directed_stop.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/services/ptv/ptv_base_service.dart';
import 'package:flutter_project/services/ptv/ptv_direction_service.dart';
import 'package:flutter_project/services/utility/list_extensions.dart';

// todo: move this class somewhere else
class RouteStops {
  Route route;
  List<Stop> stops;
  // todo: note landmarks somewhere

  RouteStops({required this.route, required this.stops});

  @override
  String toString() {
    return "\n${route.number} - ${route.name}\n\t${stops.map((s) => s.id).toList()}";
  }
}

class PtvStopService extends PtvBaseService {
  PtvDirectionService directionService = PtvDirectionService();

  /// Fetch Stops near a Location and saves them to the database.
  /// This function also creates a link between the stop and route it's on.
  // todo: think about if getting from the database is even needed here. Since it's impossible to save every stop around a location. And if you were to retrieve it from database, it would be incomplete, so you'd have to call the api anyway. Might as well just keep it to doing the api call
  Future<List<Stop>> fetchStopsByLocation({required String location, int? routeType, int? maxDistance}) async {
    List<Stop> stopList = [];
    List<Future> futures = [];    // holds all Futures for database async operations

    // 1. Fetching data
    var data = await apiService.stopsLocation(
        location, routeTypes: routeType?.toString(), maxDistance: maxDistance?.toString());

    // Early Exit
    if (data == null) {
      handleNullResponse("fetchStopsLocation");
      return [];
    }

    // 2. Populate stops list
    for (var stop in data["stops"]) {
      Stop newStop = Stop.fromApi(stop);
      stopList.add(newStop);
      futures.add(database.addStop(id: newStop.id, name: newStop.name, latitude: newStop.latitude!, longitude: newStop.longitude!, landmark: newStop.landmark));

      // 3. Add route-stop relationship to database
      int selectedRouteType = stop["route_type"];
      for (var route in stop["routes"]) {
        int routeId = route["route_id"];
        int currRouteTypeId = route["route_type"];
        futures.add(database.addStopRouteType(newStop.id, currRouteTypeId));

        if (route["route_type"] != selectedRouteType) {
          continue;
        }

        futures.add(database.addRouteStop(routeId, newStop.id));
      }
    }

    // 4. Wait for all Futures to complete
    await Future.wait(futures);

    return stopList;
  }

  /// Fetch Stops along a Route and saves them to the database, with a filter to remove old/unused stops.
  /// Also saves the link between the route and its stops.
  // todo: fetch data from database first, preferring database
  // todo: filter stops using gtfs, to match gtfs
  Future<List<Stop>> fetchStopsByRoute({required Route route, Direction? direction, bool? filter}) async {
    List<Stop> stopList = [];

    // 1. Determine which direction to use
    // If no direction is specified, sequence will not be available
    List<Direction> directions = await directionService.fetchDirections(route.id);
    int directionId;
    if (direction != null && directions.contains(direction)) {
      directionId = direction.id;
    } else {
      directionId = directions[0].id;
    }

    var data = await apiService.stopsRoute(
      route.id.toString(),
      route.type.id.toString(),
      directionId: directionId.toString(), // null if no direction available
    );

    // Empty JSON Response
    if (data == null) {
      handleNullResponse("fetchStopsRoute");
      return stopList;
    }

    // 2. Convert departure time response to DateTime object
    for (var stop in data["stops"]) {
      Stop newStop = Stop.fromApi(stop);

      // 2a. Filter skips stops that don't exist anymore
      if (filter == true && (newStop.stopSequence == 0)) { continue; }

      stopList.add(newStop);

      // 3. Add to database
      await database.addStop(id: newStop.id, name: newStop.name, latitude: newStop.latitude!, longitude: newStop.longitude!, landmark: newStop.landmark, suburb: newStop.suburb);
      await database.addRouteStop(route.id, newStop.id);
      await database.addStopRouteDirection(stopId: newStop.id, routeId: route.id, directionId: directionId, sequence: newStop.stopSequence);
    }
    // todo: add to database, generate flipped stopDirections

    return stopList;
  }

  /// Splits a ptv Stop by direction of travel
  // todo: rename this, and use gtfs (maybe in fetchStopsRoute)
  // todo: maybe change this to stop instead of stopId? I'm using stopId because what if Stop isn't initialised/in database yet? It gets fetched from fetchStopsRoute
  // todo: add cases for 0 and 1 routes
  // todo: minimise api calls
  Future<List<DirectedStop>?> splitStop({required List<Route> routes, required int stopId}) async {
    List<DirectedStop> directedStops = [];
    List<RouteStops> routesStops = [];

    // print("0. ( ptv_service -> commonStops ) -- Stops from: ${stopId}");

    // 1. Get stops along each route, and add to routesStops list
    for (var route in routes) {
      await route.loadDetails();    // ensure directions is loaded
      List<Direction>? directions = route.directions;

      // No directions for route (error)
      if (directions == null || directions.isEmpty) {
        return [];
      }

      List<Stop> stops = await fetchStopsByRoute(route: route, direction: directions.first, filter: true);
      routesStops.add(RouteStops(route: route, stops: stops));
    }
    // print("1. ( ptv_service.dart -> commonStops ) -- Routes and Stops:\n$routesStops");

    // 2. Get the index of the RouteStop, where it's Stop's id is equal to stopId
    int stopIndex = routesStops.first.stops.indexWhere((s) => s.id == stopId);

    // No match case
    if (stopIndex == -1) {
      // todo: throw an exception here
      return null;
    }

    Stop selectedStop = routesStops.first.stops[stopIndex];
    // print("2. ( ptv_service.dart -> commonStops ) -- routesStops.first.stops[$stopIndex] = ${selectedStop.id}");

    // 3. Get common contiguous stops from a stop
    // todo: probably also do a common suburbs and landmarks
    List<Stop> initialStopList = routesStops.first.stops;
    List<Stop> sharedStops = routesStops.fold(initialStopList, (accumulator, nextRouteStop) => accumulator.sharedSublist(nextRouteStop.stops, selectedStop));
    // print("3. ( ptv_service.dart -> commonStops ) -- shared contiguous stops from stop $stopId: ${sharedStops.map((s) => s.id)}");

    if (sharedStops.isEmpty) {
      return null;
    }

    // 4. Add trips
    // Align the Routes' stop orders (if possible, by destination/stop/landmark/city-bound)
    List<Trip> trips = [];
    List<Trip> tripsReversed = [];

    for (var rs in routesStops) {
      List<Stop> stopOrder = rs.stops;
      List<Stop> reversedStopOrder = stopOrder.reversed.toList();
      Direction direction = rs.route.directions!.first;
      // print("4. ( ptv_service.dart -> commonStops ) -- stops in sharedStops = ${stopOrder.containsSublist(sharedStops)}");

      bool forwardMatch = stopOrder.containsSublist(sharedStops);
      bool reverseMatch = reversedStopOrder.containsSublist(sharedStops);
      // todo: case, if there is only 1 shared stop, both forward and reverse match will be true. How to deal with this?

      if (forwardMatch || reverseMatch) {
        Direction? reversedDirection = await directionService.getReverse(route: rs.route, direction: direction);

        // 4a.
        if (forwardMatch) {
          // add current to forward triplist
          Trip trip = Trip(stop: selectedStop, route: rs.route, direction: direction);
          trips.add(trip);

          // add reversed to reverse triplist
          if (reversedDirection != null) {
            Trip reversedTrip = Trip(stop: selectedStop, route: rs.route, direction: reversedDirection);
            tripsReversed.add(reversedTrip);
          }
        }

        // 4b.
        // todo: can i use an else if here instead
        if (reverseMatch) {
          // add current to reverse triplist
          Trip trip = Trip(stop: selectedStop, route: rs.route, direction: direction);
          tripsReversed.add(trip);

          // add reversed to forward triplist
          if (reversedDirection != null) {
            Trip reversedTrip = Trip(stop: selectedStop, route: rs.route, direction: reversedDirection);
            trips.add(reversedTrip);
          }
        }
      }
    }

    // print("4. ( ptv_service.dart -> commonStops ) -- Forward Trips (${trips.map((t) => (t.route!.number, t.direction!.name)).toList()})");
    // print("4. ( ptv_service.dart -> commonStops ) -- Reverse Trips (${tripsReversed.map((t) => (t.route!.number, t.direction!.name)).toList()})");


    // 5. Create directed stops
    String? forwardDirection = sharedStops.last.id.toString();
    String? reverseDirection = sharedStops.first.id.toString();

    DirectedStop forwardStop = DirectedStop(trips: trips, stop: selectedStop, direction: forwardDirection);
    DirectedStop reverseStop = DirectedStop(trips: tripsReversed, stop: selectedStop, direction: reverseDirection);
    directedStops.add(forwardStop);
    directedStops.add(reverseStop);

    // print("5. ( ptv_service.dart -> commonStops ) -- Forward Stop: $forwardStop");
    // print("5. ( ptv_service.dart -> commonStops ) -- Reverse Stop: $reverseStop");

    // todo: what if they only share one stop
    // todo: what if the stop is on the end of the shared stop

    return directedStops;
  }
}