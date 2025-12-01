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

  /// Adds GTFS Schedule data to database
  // todo: add functionality to skip initialisation if the data is up to date, or files aren't there
  Future<void> initialise() async {
    DateTime startTime = DateTime.now();

    // todo: check if version update needed
    await _initialiseRoutes();

    DateTime endTime = DateTime.now();
    int duration = endTime.difference(startTime).inSeconds;
    print(
        "( gtfs_service.dart -> initialise ) -- finished in $duration seconds");
  }

  /// Add gtfs routes to database.
  Future<void> _initialiseRoutes() async {
    // 1. Collect routes and relevant info
    var routes = await gtfsApi.tramRoutes();

    for (var route in routes) {
      String routeId = route["route_id"];
      String shortName = route["route_short_name"];
      String longName = route["route_long_name"];

      // 2. Insert each route to the database
      await database.addGtfsRoute(
          id: routeId, shortName: shortName, longName: longName);    }
  }

  /// Fetches all gtfs trips offered by PTV for a GTFS Route within a time period.
  /// If no route data is in database, it fetches from the GTFS API and stores it to database.
  Future<List<db.GtfsTripsTableData>> fetchGtfsTrips(String gtfsRouteId) async {
    // 1. Collect from database, if it exists
    List<db.GtfsTripsTableData> gtfsTripList = await database.getGtfsTripsByRouteId(gtfsRouteId);

    // 2. Collect from API, if it doesn't exist
    if (gtfsTripList.isEmpty) {
      List<db.GtfsTripsTableCompanion> dbTripList = [];
      List? trips = await gtfsApi.tramTrips(gtfsRouteId);

      for (var trip in trips) {
        String tripId = trip["trip_id"];
        String routeId = trip["route_id"];
        String shapeId = trip["shape_id"];
        String tripHeadsign = trip["trip_headsign"];
        int wheelchairAccessible =
            int.tryParse(trip["wheelchair_accessible"]) ??
                0; // 0 indicates "no data"

        // 2a. Create Trip Companions for database insertion
        var newGtfsTrip = database.createGtfsTripCompanion(
            tripId: tripId,
            routeId: routeId,
            shapeId: shapeId,
            tripHeadsign: tripHeadsign,
            wheelchairAccessible: wheelchairAccessible);
        dbTripList.add(newGtfsTrip);
      }

      // 2b. Batch insert trips to the database
      await database.addGtfsTrips(trips: dbTripList);

      // 2c. Get trips from updated database
      gtfsTripList = await database.getGtfsTripsByRouteId(gtfsRouteId);
    }

    print(gtfsTripList.length);
    return gtfsTripList;
  }

  /// Fetches the shape of a route offered by PTV.
  /// If no shape data is in the database, it fetches from GTFS API and stored it to database.
  /// todo
  Future<List<db.GtfsShapesTableData>> fetchGtfsShapes(String gtfsRouteId) async {
    // 1. Get data from database, if it exists
    // 2. If nothing in db
      // 3. Run Fetch GTFS Trips to initialise data, to get associations between Trip's attributes (route id and shape id)
      // 4. getGTFSShapes from API service
    // 5. Return
    return [];
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

  /// Fetches the general Geopath of a GTFS Route.
  // todo: Use trips in the future to get more specific geopaths
  // todo: if geopath is shorter than the general, maybe make a warning for the app? Like its a 19d or 58a
  Future<List<LatLng>> fetchGeoPath(String routeId, {String? direction}) async {
    // 1. Collect shape data for the route
    // todo: add database check first, then api check
    // to collect shape data, collect trip data first

    // 2. Get GeoPath data from database
    List<db.GtfsShapesTableData> geoPathData = await database.getGeoPath(routeId, direction: direction);

    // 3. Convert Data to LatLng
    List<LatLng> geoPath = geoPathData.map((e) => LatLng(e.latitude, e.longitude)).toList();
    return geoPath;
  }

  /// Returns a list of LatLng objects representing the current positions of trams on a specified route.
  // todo: map ptv routeId to gtfs routeId by name (shortname then longname)
  // todo: edge case, combined routes (501-503)
  Future<List<LatLng>> getTramPositions(int routeId) async {
    List<LatLng> locations = [];
    final feedMessage = await gtfsApi.tramVehiclePositions();

    // 1. Map PTV route ID to GTFS route ID
    String? gtfsRouteId = await database.convertToGtfsRouteId(routeId);

    // 2. Get GTFS route IDs associated with the route
    List<db.GtfsTripsTableData>? trips = gtfsRouteId != null
        ? await database.getGtfsTripsByRouteId(gtfsRouteId)
        : null;
    List<String>? tripIds =
        trips?.map((t) => t.id).toList(); // Converts trips to tripIds

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
    final feedMessage = await gtfsApi.tramTripUpdates();

    for (var entity in feedMessage.entity) {
      print(entity);
    }
  }

  Future<String?> convertPtvRouteToGtfs(Route route) async {
    String? gtfsRouteId = await database.convertToGtfsRouteId(route.id);
    return gtfsRouteId;
  }
}
