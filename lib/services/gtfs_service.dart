import 'dart:io';

import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/database/helpers/gtfs_route_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_trip_helpers.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

/* GTFS Steps
- Getting GTFS Datasets (GTFS Route, GTFS Shapes)
1. todo: figure this part out (setup a server, OR use github actions) https://claude.ai/chat/b0dad283-a1ad-4c19-81cc-493659c7185d

- Mapping GTFS to PTV (Locations)
1. Get GTFS Routes (route_id)
2. Get GTFS Trips (trip_id, route_id, direction_id)

- GeoPath
1. Get GTFS Shapes (shape_id)
2. Get GTFS Trips(trip_id, shape_id, route_id)
*/

class GtfsService {
  String routesFilePath = "lib/dev/routes.txt";
  String tripsFilePath = "lib/dev/trips.txt";
  db.AppDatabase database = Get.find<db.AppDatabase>();

  /// Adds GTFS Schedule data to database
  // todo: add functionality to skip initialisation if the data is up to date
  Future<void> initialise() async {
    await _initialiseRoutes();
    await _initialiseTrips();
  }

  /// Add gtfs routes to database.
  Future<void> _initialiseRoutes() async {
    try {
      final gtfsRoutesMap = await csvToMapList(routesFilePath);
      for (var route in gtfsRoutesMap) {
        String routeId = route["route_id"];
        String shortName = route["route_short_name"];
        String longName = route["route_long_name"];

        await database.addGtfsRoute(
            id: routeId, shortName: shortName, longName: longName);
      }
    } catch (e) {
      print("Error $e");
    }
  }

  /// Add gtfs trips to database.
  Future<void> _initialiseTrips() async {
    try {
      List<db.GtfsTripsTableCompanion> gtfsTripList = [];
      final gtfsTripsMap = await csvToMapList(tripsFilePath);

      // Add gtfs trips to database, by adding the rows in the map to a list, and batch inserting it to the database.
      for (var trip in gtfsTripsMap) {
        String tripId = trip["trip_id"];
        String routeId = trip["route_id"];
        String tripHeadsign = trip["trip_headsign"];
        // int wheelchairAccessible = trip["wheelchair_accessible"];
        int wheelchairAccessible = int.tryParse(trip["wheelchair_accessible"]) ?? 0;    // todo: fix this. It takes a long time (maybe bc its big) but seems a bit buggy

        var newGtfsTrip = database.createGtfsTripCompanion(tripId: tripId, routeId: routeId, tripHeadsign: tripHeadsign, wheelchairAccessible: wheelchairAccessible);
        gtfsTripList.add(newGtfsTrip);
      }

      // Batch inserting trips to database
      await database.addGtfsTrips(trips: gtfsTripList);
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

  // todo:
  // todo: map ptv routeId to gtfs routeId by name (shortname then longname)
  // todo: edge case, combined routes (501-503)
  Future<void> getTramPositions(int routeId) async {
    final feedMessage = await gtfsApiService.tramVehiclePositions();

    // for (var entity in feedMessage.entity) {
    //   // if (entity.vehicle.trip.tripId)
    //   print(entity);
    // }

    print(feedMessage);
  }

// /// Get status Updates for a specific tram route via GTFS
// // todo: move this to ptv_service
// Future<List<TripUpdate>> getTripUpdatesRoute(String routeId) async {
//   final feedMessage = await tramTripUpdates();
//
//   // for (var entity in feedMessage.entity) {
//   // }
//
//   print(feedMessage);
//
//   return feedMessage.entity
//       .where((entity) => entity.hasTripUpdate())          // filters entities to trips with tripUpdates
//       .map((entity) => entity.tripUpdate)                 // turns all those entities to tripUpdates
//       .where((update) => update.trip.routeId == routeId)  // filters all tripUpdates to those with same routeId
//       .toList();                                          // turns it into a list
// }
//
// Future<void> getTramAlert(String id) async {
//   final feedMessage = await tramServiceAlerts();
//
//   print(feedMessage);
// }
}
