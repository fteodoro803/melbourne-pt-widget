import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/database/helpers/gtfs_route_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_shapes_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_trip_helpers.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GtfsRealtimeService {
  GtfsApiService gtfsApi = GtfsApiService();
  db.Database database = Get.find<db.Database>();

  /// Add gtfs routes to database.
  Future<List<db.GtfsRoutesTableData>> fetchGtfsRoutes() async {
    // 1. Collect routes from database, if they exist
    List<db.GtfsRoutesTableData> gtfsRouteList = await database.getGtfsRoutes();

    // 2. Collect from API, if they don't exist
    if (gtfsRouteList.isEmpty) {
      var routes = await gtfsApi.tramRoutes();

      for (var route in routes) {
        String routeId = route["route_id"];
        String shortName = route["route_short_name"];
        String longName = route["route_long_name"];

        // 2a. Insert each route to the database
        await database.addGtfsRoute(
            id: routeId, shortName: shortName, longName: longName);
      }

      // 2b. Get routes from database
      gtfsRouteList = await database.getGtfsRoutes();
    }

    return gtfsRouteList;
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
        int wheelchairAccessible = trip["wheelchair_accessible"];

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

    return gtfsTripList;
  }

  /// Fetch the GTFS Shape data of a Route given a route id.
  /// Needs GTFS Trips data to function.
  Future<List<db.GtfsShapesTableData>> fetchShapes(String routeId) async {
    // 1. Collect from database, if it exists
    List<db.GtfsShapesTableData> gtfsShapeList = await database.getGtfsShapes(routeId);

    // 2. Collect from API, if it doesn't exist
    if (gtfsShapeList.isEmpty) {
      // Trips data is needed for shapes to properly function
      await fetchGtfsTrips(routeId);

      List<db.GtfsShapesTableCompanion> dbShapeList = [];
      List? shapes = await gtfsApi.tramRouteShapes(routeId);

      for (var shape in shapes) {
        String id = shape["shape_id"];
        double latitude = shape["shape_pt_lat"];
        double longitude = shape["shape_pt_lon"];
        int sequence = shape["shape_pt_sequence"];


        // 2a. Create Shape Companions for database insertion
        db.GtfsShapesTableCompanion newGtfsShape = database.createGtfsShapeCompanion(
          id: id,
          latitude: latitude,
          longitude: longitude,
          sequence: sequence
        );
        dbShapeList.add(newGtfsShape);
      }

      // 2b. Batch insert shapes to the database
      await database.addGtfsShapes(geoPath: dbShapeList);

      // 2c. Get shapes from updated database
      gtfsShapeList = await database.getGtfsShapes(routeId);
    }

    return gtfsShapeList;
  }

  /// Fetch GTFS Shapes of a Route given a Route ID

  /// Fetches the general Geopath of a GTFS Route.
  // todo: Use trips in the future to get more specific geopaths
  // todo: if geopath is shorter than the general, maybe make a warning for the app? Like its a 19d or 58a
  Future<List<LatLng>> fetchGeoPath(String routeId, {String? direction}) async {
    // 1. Check if GTFS Shape data exists
    bool hasShapeData = await database.gtfsShapeHasData(routeId);

    // If it doesn't exist, fetch from API
    if (hasShapeData != true) {
      await fetchShapes(routeId);
    }

    // 2. Get most-common GeoPath for the route from database
    List<db.GtfsShapesTableData> geoPathData = await database.getGeoPath(routeId, direction: direction);

    // 3. Convert Data to LatLng
    List<LatLng> geoPath = geoPathData.map((e) => LatLng(e.latitude, e.longitude)).toList();

    return geoPath;
  }
}