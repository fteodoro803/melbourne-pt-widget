import 'dart:io';

import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/database/helpers/geopath_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_route_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_trip_helpers.dart';
import 'package:flutter_project/database/helpers/route_helpers.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:csv/csv.dart';

/* GTFS Steps
- Getting GTFS Datasets (GTFS Route, GTFS Shapes)
1. todo: figure this part out (setup a server, OR use github actions) https://claude.ai/chat/b0dad283-a1ad-4c19-81cc-493659c7185d

- Mapping GTFS to PTV (Locations)
1. Get GTFS Routes (route_id)
2. Get GTFS Trips (trip_id, route_id, direction_id)

- todo: GeoPath
1. Get GTFS Shapes (shape_id)
2. Get GTFS Trips(trip_id, shape_id, route_id)
- todo: accurate stops locations
*/

class GtfsService {
  GtfsApiService gtfsApiService = GtfsApiService();
  String tramRoutesFile = "lib/dev/gtfs/metro_tram/routes.txt";
  String tramTripsFile = "lib/dev/gtfs/metro_tram/trips.txt";

  // String trainRoutesFile = "lib/dev/gtfs/metro_train/routes.txt";
  // String trainTripsFile = "lib/dev/gtfs/metro_train/trips.txt";
  //
  // String busRoutesFile = "lib/dev/gtfs/metro_bus/routes.txt";
  // String busTripsFile = "lib/dev/gtfs/metro_bus/trips.txt";
  db.AppDatabase database = Get.find<db.AppDatabase>();

  /// Adds GTFS Schedule data to database
  // todo: add functionality to skip initialisation if the data is up to date
  Future<void> initialise() async {
    DateTime startTime = DateTime.now();

    // // Metro trains
    // await _initialiseRoutes(trainRoutesFile);
    // await _initialiseTrips(trainTripsFile);

    // Metro trams
    await _initialiseRoutes(tramRoutesFile);
    await _initialiseTrips(tramTripsFile);
    await _initialiseGeoPaths();

    // // Metro buses
    // await _initialiseRoutes(busRoutesFile);
    // await _initialiseTrips(busTripsFile);

    DateTime endTime = DateTime.now();
    int duration = endTime.difference(startTime).inSeconds;
    print("( gtfs_service.dart -> initialise ) -- finished in $duration seconds");
  }

  /// Add gtfs routes to database.
  Future<void> _initialiseRoutes(String routeFilePath) async {
    try {
      // 1. Collect routes and relevant information from the gtfsRoutesMap
      final gtfsRoutesMap = await csvToMapList(routeFilePath);
      for (var route in gtfsRoutesMap) {
        String routeId = route["route_id"];
        String shortName = route["route_short_name"];
        String longName = route["route_long_name"];

        // 2. Insert each trip to the database
        await database.addGtfsRoute(
            id: routeId, shortName: shortName, longName: longName);
      }
    } catch (e) {
      print("Error $e");
    }
  }

  /// Add gtfs trips to database.
  Future<void> _initialiseTrips(String tripFilePath) async {
    try {
      List<db.GtfsTripsTableCompanion> gtfsTripList = [];

      // 1. Collect trips and relevant information from the gtfsTripsMap
      final gtfsTripsMap = await csvToMapList(tripFilePath);
      for (var trip in gtfsTripsMap) {
        String tripId = trip["trip_id"];
        String routeId = trip["route_id"];
        String shapeId = trip["shape_id"];
        String tripHeadsign = trip["trip_headsign"];
        int wheelchairAccessible = int.tryParse(trip["wheelchair_accessible"]) ?? 0;    // 0 indicates "no data"

        var newGtfsTrip = database.createGtfsTripCompanion(tripId: tripId, routeId: routeId, shapeId: shapeId, tripHeadsign: tripHeadsign, wheelchairAccessible: wheelchairAccessible);
        gtfsTripList.add(newGtfsTrip);
      }

      // 2. Batch insert trips to the database
      await database.addGtfsTrips(trips: gtfsTripList);
    }
    catch (e) {
      print("Error $e");
    }
  }

  /// Add gtfs shapes to database.
  // fixme: this probably shouldn't be here. Maybe create an API endpoint that collects shapes for a specific route
  Future<void> _initialiseGeoPaths() async {
    String tempShapesFilePath = "lib/dev/gtfs/metro_tram/shapes.txt";

    try {
      List<db.GeoPathsTableCompanion> geoPaths = [];

      // 1. Collect shapes from gtfsShapesMap
      final gtfsShapesMap = await csvToMapList(tempShapesFilePath);
      for (var geopath in gtfsShapesMap) {
        String id = geopath["shape_id"];
        int sequence = int.tryParse(geopath["shape_pt_sequence"]) ?? -1;
        double latitude = double.tryParse(geopath["shape_pt_lat"]) ?? -1;
        double longitude = double.tryParse(geopath["shape_pt_lon"]) ?? -1;

        var newGeoPath = database.createGeoPathCompanion(id: id, sequence: sequence, latitude: latitude, longitude: longitude);
        geoPaths.add(newGeoPath);
      }

      // 2. Batch insert geoPaths to the database
      await database.addGeoPaths(geoPath: geoPaths);
    }
    catch (e) {
      print("Error $e");
    }
  }

  /// Converts CSV to Map
  Future<List<Map<String, dynamic>>> csvToMapList(String filePath) async {
    List<Map<String, dynamic>> mapList = [];

    final file = File(filePath);
    final content = await file.readAsString();

    List<List<dynamic>> rows = CsvToListConverter().convert(content);
    final headers = rows.first.map((c) => c.toString()).toList();
    final dataRows = rows.skip(1);    // skips the header row

    // Creates a Map with headers as keys, and rows as values, and adds to list
    for (var row in dataRows) {
      final mappedRow = Map.fromIterables(headers, row);
      mapList.add(mappedRow);
    }

    return mapList;
  }

  /// Returns a list of LatLng objects representing the current positions of trams on a specified route.
  // todo: map ptv routeId to gtfs routeId by name (shortname then longname)
  // todo: edge case, combined routes (501-503)
  Future<List<LatLng>> getTramPositions(int routeId) async {
    List<LatLng> locations = [];
    final feedMessage = await gtfsApiService.tramVehiclePositions();
    String? gtfsRouteId;

    // 1. Map PTV route ID to GTFS route ID
    var ptvRouteData = await database.getRouteById(routeId);
    if (ptvRouteData != null) {
      var ptvRoute = ptvRouteData.toCompanion(true);
      var gtfsRoute = await database.getGtfsRouteFromPtvRoute(ptvRoute, "tram");

      gtfsRouteId = gtfsRoute?.id;
      // print("( gtfs_service.dart -> getTramPositions ) -- \n\tptvRoute: $ptvRouteData, \n\tgtfsRoute: $gtfsRoute");
    }

    // 2. Get GTFS route IDs associated with the route
    List<db.GtfsTripsTableData>? trips = gtfsRouteId != null ? await database.getGtfsTripsByRouteId(gtfsRouteId) : null;
    List<String>? tripIds = trips?.map((t) => t.id).toList();     // Converts trips to tripIds

    // 3. Collect positions of vehicles
    if (tripIds != null) {
      for (var entity in feedMessage.entity) {
        if (tripIds.contains(entity.vehicle.trip.tripId)) {
          double latitude = entity.vehicle.position.latitude;
          double longitude = entity.vehicle.position.longitude;
          LatLng newLocation = LatLng(latitude, longitude);
          locations.add(newLocation);
        }
      }
    }

    return locations;
  }

  Future<void> getTramTripUpdates() async {
    final feedMessage = await gtfsApiService.tramTripUpdates();

    for (var entity in feedMessage.entity) {
      print(entity);
    }
  }
}
