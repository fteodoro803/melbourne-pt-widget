import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/database/helpers/gtfs_shapes_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_assets_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_route_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_trip_helpers.dart';
import 'package:flutter_project/database/helpers/route_map_helpers.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/services/gtfs/gtfs_realtime_service.dart';
import 'package:flutter_project/services/gtfs/gtfs_schedule_service.dart';
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
  GtfsApiService gtfsApi = GtfsApiService();
  db.Database database = Get.find<db.Database>();
  GtfsRealtimeService realtime = GtfsRealtimeService();
  GtfsScheduleService schedule = GtfsScheduleService();

  /// Adds GTFS Schedule data to database
  // todo: add functionality to skip initialisation if the data is up to date, or files aren't there
  Future<void> initialise() async {
    DateTime startTime = DateTime.now();

    // todo: check if version update needed
    await realtime.fetchGtfsRoutes();

    DateTime endTime = DateTime.now();
    int duration = endTime.difference(startTime).inSeconds;
    print(
        "( gtfs_service.dart -> initialise ) -- finished in $duration seconds");
  }


  // /// Add gtfs shapes to database.
  // // fixme: this probably shouldn't be here. Maybe create an API endpoint that collects shapes for a specific route
  // Future<void> _initialiseGeoPaths(String shapesFilePath) async {
  //   String assetName = "shapes.txt";
  //
  //   try {
  //     final file = File(shapesFilePath);
  //     DateTime newAssetDate = await file.lastModified();
  //     DateTime? previousAssetDate =
  //         await database.getGtfsAssetDate(id: assetName);
  //
  //     // Early exit if new data is equal to or older than previous data
  //     if (previousAssetDate != null &&
  //         !newAssetDate.isAfter(previousAssetDate)) {
  //       print(
  //           "( gtfs_service.dart -> _initialiseGeoPaths ) -- current data is up-to-date, skipping initialisation");
  //       return;
  //     }
  //
  //     // 1. If previous data exists, clear previous data in GtfsRoute
  //     if (previousAssetDate != null &&
  //         newAssetDate.isAfter(previousAssetDate)) {
  //       print(
  //           "( gtfs_service.dart -> _initialiseGeoPaths ) -- clearing GeoPath Table; prevAssetDate={$previousAssetDate}, newAssetDate={$newAssetDate}; newAssetDate.isAfter(prevAssetDate)={${newAssetDate.isAfter(previousAssetDate)}}");
  //       await database.clearGeoPathsTable();
  //     }
  //
  //     // 2. Collect shapes from gtfsShapesMap
  //     List<db.GeoPathsTableCompanion> geoPaths = [];
  //     final gtfsShapesMap = await csvToMapList(shapesFilePath);
  //     for (var geopath in gtfsShapesMap) {
  //       String id = geopath["shape_id"];
  //       int sequence = int.tryParse(geopath["shape_pt_sequence"]) ?? -1;
  //       double latitude = double.tryParse(geopath["shape_pt_lat"]) ?? -1;
  //       double longitude = double.tryParse(geopath["shape_pt_lon"]) ?? -1;
  //
  //       var newGeoPath = database.createGeoPathCompanion(
  //           id: id,
  //           sequence: sequence,
  //           latitude: latitude,
  //           longitude: longitude);
  //       geoPaths.add(newGeoPath);
  //     }
  //
  //     // 3. Batch insert geoPaths to the database
  //     await database.addGeoPaths(geoPath: geoPaths);
  //
  //     // 4. Add routes asset file info to database
  //     await database.addGtfsAsset(id: assetName, dateModified: newAssetDate);
  //   } catch (e) {
  //     print("Error $e");
  //   }
  // }



  Future<String?> convertPtvRouteToGtfs(Route route) async {
    String? gtfsRouteId = await database.convertToGtfsRouteId(route.id);
    return gtfsRouteId;
  }
}
