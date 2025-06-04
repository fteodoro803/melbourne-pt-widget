// Handles business logic for Departures, between the UI and HTTP Requests

import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/database/helpers/direction_helpers.dart';
import 'package:flutter_project/database/helpers/link_stop_directions_helpers.dart';
import 'package:flutter_project/database/helpers/route_helpers.dart';
import 'package:flutter_project/database/helpers/link_route_stops_helpers.dart';
import 'package:flutter_project/database/helpers/route_type_helpers.dart';
import 'package:flutter_project/database/helpers/stop_helpers.dart';
import 'package:flutter_project/database/helpers/link_stop_route_types_helpers.dart';
import 'package:flutter_project/database/helpers/trip_helpers.dart';
import 'package:flutter_project/domain/directed_stop.dart';
import 'package:flutter_project/domain/disruption.dart';
import 'package:flutter_project/geopath.dart';
import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/services/ptv/ptv_departure_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_project/services/utility/list_extensions.dart';

import '../database/database.dart' as db;
import 'package:get/get.dart';

import 'ptv/ptv_direction_service.dart';

class StopRouteLists {
  List<Stop> stops;
  List<Route> routes;

  StopRouteLists(this.stops, this.routes);
}

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

/// Handles calling the PTV API, converting to domain models, and storing to database

class PtvService {
  db.AppDatabase database = Get.find<db.AppDatabase>();
  final PtvDepartureService departures = PtvDepartureService();
  final PtvDirectionService directions = PtvDirectionService();

// Disruption Functions
  /// Fetches disruptions for a given route.
  Future<List<Disruption>> fetchDisruptions(Route route) async {
    List<Disruption> disruptions = [];

    // Fetches disruption data via PTV API
    ApiData data = await PtvApiService().disruptions(route.id.toString());
    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print("( ptv_service.dart -> fetchDisruptions ) -- Null data response");
      return [];
    }

    String routeType = "";
    if (route.type == RouteType.train) {    // todo: add the other route types (vLine, nightBus)
      routeType = "metro_train";
    }
    else if (route.type == RouteType.tram) {
      routeType = "metro_tram";
    }
    else if (route.type == RouteType.bus) {
      routeType = "metro_bus";
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var disruption in jsonResponse["disruptions"][routeType]) {
      Disruption newDisruption = Disruption.fromApi(data: disruption);
      disruptions.add(newDisruption);
    }

    return disruptions;
  }

// GeoPath Functions
  // todo: add to database
  Future<List<LatLng>> fetchGeoPath(Route route) async {
    List<LatLng> pathList = [];

    // Fetches stops data via PTV API
    ApiData data = await PtvApiService().stopsRoute(
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
  // todo: use fromApi constructor
  // todo: add to database
  Future<List<Departure>> fetchPattern(Trip trip, Departure departure) async {
    List<Departure> departures = [];

    // if (departure == null) {
    //   return [];
    // }

    String expands = "Stop";
    String? runRef = departure.runRef;
    RouteType? routeType = trip.route?.type;
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
      String? platformNumber = departure["platform_number"];
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
          hasAirConditioning: hasAirConditioning,
          platformNumber: platformNumber
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
  /// Fetches all routes offered by PTV from the database.
  /// If no route data is in database, it fetches from the PTV API and stores it to database.
  Future<List<Route>> fetchRoutes({String? routeTypes}) async {
    List<Route> routeList = [];

    // Checks if data exists in database, and sets routeList if it exists
    int? routeType = routeTypes != null ? int.tryParse(routeTypes) : null;
    final dbRouteList = await Get.find<db.AppDatabase>().getRoutes(routeType);
    if (dbRouteList.isNotEmpty) {
      routeList = dbRouteList.map(Route.fromDb).toList();
    }

    // Fetches data from API and adds to database, if route data doesn't exist in database
    else {
      // Fetches stop data via PTV API
      ApiData data = await PtvApiService().routes(routeTypes: routeTypes);
      Map<String, dynamic>? jsonResponse = data.response;

      // Empty JSON Response
      if (jsonResponse == null) {
        print("(ptv_service.dart -> fetchRoutes) -- Null data response");
        return [];
      }

      // Creates new routes, and adds them to return list and database
      for (var route in jsonResponse["routes"]) {
        Route newRoute = Route.fromApi(route);
        routeList.add(newRoute);

        // Add to Database
        await Get.find<db.AppDatabase>().addRoute(
            newRoute.id, newRoute.name, newRoute.number, newRoute.type.id,
            newRoute.gtfsId, newRoute.status);
      }
    }

    return routeList;
  }

  /// Fetches routes from database, by search name.
  Future<List<Route>> searchRoutes({String? query, RouteType? routeType}) async {
    final dbRouteList = await Get.find<db.AppDatabase>().getRoutesByName(search: query, routeType: routeType?.id);
    List<Route> domainRouteList = dbRouteList.map(Route.fromDb).toList();
    return domainRouteList;
  }

  /// Fetches routes from database, by id.
  Future<Route?> getRouteById({required int id, bool withDetails = false}) async {
    final dbRoute = await Get.find<db.AppDatabase>().getRouteById(id);
    Route? route = dbRoute != null ? Route.fromDb(dbRoute) : null;

    if (withDetails == true && route != null) await route.loadDetails();

    return route;
  }

  /// Fetches routes according to a stop, from the database.
  /// Maps the databases' routes to domain's route
  // todo: consider change this to getRoutesFromStop, or something like that. Fetch is reserved for functions with API calls
  // todo: but also, in our functions, we use fetch, but most of them also check the database first. So maybe for consistency, keep it?
  Future<List<Route>> fetchRoutesFromStop(int stopId) async {
    final List<db.RoutesTableData> dbRoutes = await Get.find<db.AppDatabase>().getRoutesFromStop(stopId);

    // Convert Route's database model to domain model
    List<Route> routeList = dbRoutes.map(Route.fromDb).toList();

    return routeList;
  }

// RouteType Functions
  /// Fetches all route types offered by PTV from the database.
  /// If no route type data is in database, it fetches from the PTV API and stores it to database.  // todo: get from database first, preferring database
  Future<List<String>> fetchRouteTypes() async {
    List<String> routeTypes = [];

    // If data exists in database, adds that data to routeTypes list
    final dbRouteTypesList = await Get.find<db.AppDatabase>().getRouteTypes();
    if (dbRouteTypesList.isNotEmpty) {
      routeTypes = dbRouteTypesList.map((rt) => rt.name).toList();
    }

    // If data doesn't exist in database, fetches from API and adds it to database
    else {
      ApiData data = await PtvApiService().routeTypes();
      Map<String, dynamic>? jsonResponse = data.response;

      // Early exit: Empty response
      if (data.response == null) {
        print("( ptv_service.dart -> fetchRouteTypes ) -- Null response");
        return [];
      }

      // Populating RouteTypes list
      for (var entry in jsonResponse!["route_types"]) {
        int id = entry["route_type"];
        RouteType newRouteType = RouteType.fromId(id);
        routeTypes.add(newRouteType.name);

        // Add to database
        Get.find<db.AppDatabase>().addRouteType(
            newRouteType.id, newRouteType.name);
      }
    }

    return routeTypes;
  }

// Runs Functions
  Future<void> fetchRuns(Trip trip) async {
    String expands = "All";
    String? runRef = trip.departures?[0].runRef;
    RouteType? routeType = trip.route?.type;
    ApiData data = await PtvApiService().runs(
        runRef!, routeType!.name, expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    print("(ptv_service.dart -> fetchRuns) -- Fetched Runs:\n$jsonResponse");
  }

// Stop Functions
  /// Fetch Stops near a Location and saves them to the database.
  /// This function also creates a link between the stop and route it's on.
  // todo: think about if getting from the database is even needed here. Since it's impossible to save every stop around a location. And if you were to retrieve it from database, it would be incomplete, so you'd have to call the api anyway. Might as well just keep it to doing the api call
  Future<List<Stop>> fetchStopsLocation(String location, {int? routeType, int? maxDistance}) async {
    List<Stop> stopList = [];
    List<Future> futures = [];    // holds all Futures for database async operations

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().stopsLocation(
        location, routeTypes: routeType?.toString(), maxDistance: maxDistance?.toString());
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("( ptv_service.dart -> fetchStopsLocation ) -- null response");
      return [];
    }

    // Populating stops list and adding them to Database
    for (var stop in jsonResponse!["stops"]) {
      Stop newStop = Stop.fromApi(stop);
      stopList.add(newStop);
      futures.add(database.addStop(id: newStop.id, name: newStop.name, latitude: newStop.latitude!, longitude: newStop.longitude!, landmark: newStop.landmark));

      // Adds route-stop relationship to database
      int selectedRouteType = stop["route_type"];
      for (var route in stop["routes"]) {
        int routeId = route["route_id"];
        int currRouteTypeId = route["route_type"];
        futures.add(Get.find<db.AppDatabase>().addStopRouteType(newStop.id, currRouteTypeId));

        if (route["route_type"] != selectedRouteType) {
          continue;
        }

        futures.add(Get.find<db.AppDatabase>().addRouteStop(routeId, newStop.id));
      }
    }

    // Wait for all Futures to complete
    await Future.wait(futures);

    return stopList;
  }

  /// Fetch Stops along a Route and saves them to the database, with a filter to remove old/unused stops.
  /// Also saves the link between the route and its stops.
  // todo: fetch data from database first, preferring database
  // todo: filter stops using gtfs, to match gtfs
  Future<List<Stop>> fetchStopsRoute(Route route, {Direction? direction, bool? filter}) async {
    List<Stop> stopList = [];

    // Determine which direction to use
    // If no direction is specified, sequence will not be available
    List<Direction> directions = await this.directions.fetchDirections(route.id);
    int directionId;
    if (direction != null && directions.contains(direction)) {
        directionId = direction.id;
    } else {
      directionId = directions[0].id;
    }

    ApiData data = await PtvApiService().stopsRoute(
      route.id.toString(),
      route.type.id.toString(),
      directionId: directionId.toString(), // null if no direction available
    );
    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print(
          "(ptv_service.dart -> fetchStopsAlongDirection) -- Null data response");
      return stopList;
    }

    // Converts departure time response to DateTime object, if it's not null, and adds to departure list
    for (var stop in jsonResponse["stops"]) {
      Stop newStop = Stop.fromApi(stop);

      // Filter skips stops that don't exist anymore
      if (filter == true && (newStop.stopSequence == 0)) { continue; }

      stopList.add(newStop);

      // Add to database
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
  Future<List<DirectedStop>?> splitStop(List<Route> routes, int stopId) async {
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

      List<Stop> stops = await fetchStopsRoute(route, direction: directions.first, filter: true);
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
        Direction? reversedDirection = await directions.getReverse(rs.route, direction);

        // 4a.
        if (forwardMatch) {
          // add current to forward triplist
          Trip trip = Trip.withStopRoute(selectedStop, rs.route, direction);
          trips.add(trip);

          // add reversed to reverse triplist
          if (reversedDirection != null) {
            Trip reversedTrip = Trip.withStopRoute(selectedStop, rs.route, reversedDirection);
            tripsReversed.add(reversedTrip);
          }
        }

        // 4b.
        // todo: can i use an else if here instead
        if (reverseMatch) {
          // add current to reverse triplist
          Trip trip = Trip.withStopRoute(selectedStop, rs.route, direction);
          tripsReversed.add(trip);

          // add reversed to forward triplist
          if (reversedDirection != null) {
            Trip reversedTrip = Trip.withStopRoute(selectedStop, rs.route, reversedDirection);
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
    ApiData data = await PtvApiService().stopsLocation(
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
        String gtfsId = "TEMPORARY"; // todo: fix this
        String status = "TEMPORARY"; // todo: fix this, or the logic of the class

        Route newRoute = Route(
            name: routeName,
            number: routeNumber,
            id: routeId,
            type: routeType,
            gtfsId: gtfsId,
            status: status);

        stops.add(newStop);
        routes.add(newRoute);
      }
    }

    return StopRouteLists(stops, routes);
  }

  Future<void> saveTrip(Trip trip) async {
    String? uniqueId = trip.uniqueID;
    int? routeTypeId = trip.route?.type.id;
    int? routeId = trip.route?.id;
    int? stopId = trip.stop?.id;
    int? directionId = trip.direction?.id;
    int? index = trip.index;

    if (uniqueId != null && routeTypeId != null && routeId != null && stopId != null && directionId != null) {
      Get.find<db.AppDatabase>().addTrip(uniqueId: uniqueId, routeTypeId: routeTypeId, routeId: routeId, stopId: stopId, directionId: directionId, index: index);
    }
    else {
      print(" ( ptv_service.dart -> saveTrip ) -- one of the following is null: uniqueId, routeTypeId, routeId, stopId, directionId");
    }
  }

  /// Checks if Trip is in Database
  Future<bool> isTripSaved(Trip trip) async {
    if (trip.uniqueID != null) {
      return await Get.find<db.AppDatabase>().isTripInDatabase(trip.uniqueID!);
    }
    else {
      return false;
    }
  }

  Future<List<Trip>> loadTrips() async {
    List<Trip> tripList = [];
    db.AppDatabase database = Get.find<db.AppDatabase>();

    var dbTrips = await Get.find<db.AppDatabase>().getTrips();
    Route? route;
    Stop? stop;
    Direction? direction;
    int? index;


    // Convert database trip to domain trip
    for (var dbTrip in dbTrips) {

      var dbRoute = await database.getRouteById(dbTrip.routeId);
      route = dbRoute != null ? Route.fromDb(dbRoute) : null;

      var dbStop = await database.getStopById(dbTrip.stopId);
      stop = dbStop != null ? Stop.fromDb(dbStop: dbStop) : null;
      // todo: get sequence to stop

      var dbDirection = await database.getDirectionById(dbTrip.directionId);
      direction = dbDirection != null ? Direction.fromDb(dbDirection) : null;

      index = dbTrip.index ?? 999;

      Trip newTrip = Trip.withAttributes(stop, route, direction);
      newTrip.setIndex(index);
      tripList.add(newTrip);
    }

    return tripList;
  }

  Future<void> deleteTrip(String tripId) async {
    await Get.find<db.AppDatabase>().removeTransport(tripId);
  }

}