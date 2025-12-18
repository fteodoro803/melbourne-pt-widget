import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GtfsScheduleService {
  GtfsApiService gtfsApi = GtfsApiService();
  db.Database database = Get.find<db.Database>();

  /// Add gtfs routes to database.
  Future<List<db.GtfsRoutesTableData>> fetchGtfsRoutes() async {
    // 1. Collect routes from database, if they exist
    List<db.GtfsRoutesTableData> gtfsRouteList = await database.gtfsRoutesDao.getGtfsRoutes();

    // 2. Collect from API, if they don't exist
    if (gtfsRouteList.isEmpty) {
      var routes = [];
      var tramRoutes = await gtfsApi.routes(routeType: "tram");
      routes += tramRoutes;
      var trainRoutes = await gtfsApi.routes(routeType: "train");
      routes += trainRoutes;
      // var busRoutes = await gtfsApi.routes(routeType: "bus");
      // routes += busRoutes;

      for (var route in routes) {
        String routeId = route["route_id"];
        String shortName = route["route_short_name"];
        String? longName = route["route_long_name"];
        String colour = route["route_color"];
        String textColour = route["route_text_color"];
        int routeType = route["route_type"];

        // 2a. Insert each route to the database
        var dbGtfsRoute = database.gtfsRoutesDao.createGtfsRouteCompanion(id: routeId, shortName: shortName, longName: longName, colour: colour, textColour: textColour, routeType: routeType);
        await database.gtfsRoutesDao.addGtfsRoute(dbGtfsRoute);
      }

      // 2b. Get routes from database
      gtfsRouteList = await database.gtfsRoutesDao.getGtfsRoutes();
    }

    return gtfsRouteList;
  }

  /// Fetches all gtfs trips offered by PTV for a GTFS Route within a time period.
  /// If no route data is in database, it fetches from the GTFS API and stores it to database.
  Future<List<db.GtfsTripsTableData>> fetchGtfsTrips(String gtfsRouteId) async {
    // 1. Collect from database, if it exists
    List<db.GtfsTripsTableData> gtfsTripList = await database.gtfsTripsDao.getGtfsTripsByRouteId(gtfsRouteId);

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
        var newGtfsTrip = database.gtfsTripsDao.createGtfsTripCompanion(
            tripId: tripId,
            routeId: routeId,
            shapeId: shapeId,
            tripHeadsign: tripHeadsign,
            wheelchairAccessible: wheelchairAccessible);
        dbTripList.add(newGtfsTrip);
      }

      // 2b. Batch insert trips to the database
      await database.gtfsTripsDao.addGtfsTrips(trips: dbTripList);

      // 2c. Get trips from updated database
      gtfsTripList = await database.gtfsTripsDao.getGtfsTripsByRouteId(gtfsRouteId);
    }

    return gtfsTripList;
  }

  /// Fetch the GTFS Shape data of a Route given a route id.
  /// Needs GTFS Trips data to function.
  Future<List<db.GtfsShapesTableData>> fetchShapes(String routeId) async {
    // 1. Collect from database, if it exists
    List<db.GtfsShapesTableData> gtfsShapeList = await database.gtfsShapesDao.getGtfsShapes(routeId);

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
        db.GtfsShapesTableCompanion newGtfsShape = database.gtfsShapesDao.createGtfsShapeCompanion(
          id: id,
          latitude: latitude,
          longitude: longitude,
          sequence: sequence
        );
        dbShapeList.add(newGtfsShape);
      }

      // 2b. Batch insert shapes to the database
      await database.gtfsShapesDao.addGtfsShapes(geoPath: dbShapeList);

      // 2c. Get shapes from updated database
      gtfsShapeList = await database.gtfsShapesDao.getGtfsShapes(routeId);
    }

    return gtfsShapeList;
  }

  /// Fetch GTFS Shapes of a Route given a Route ID

  /// Fetches the general Geopath of a GTFS Route.
  // todo: Use trips in the future to get more specific geopaths
  // todo: if geopath is shorter than the general, maybe make a warning for the app? Like its a 19d or 58a
  Future<List<LatLng>> fetchGeoPath(String routeId, {String? direction}) async {
    // 1. Check if GTFS Shape data exists
    bool hasShapeData = await database.gtfsShapesDao.gtfsShapeHasData(routeId);

    // If it doesn't exist, fetch from API
    if (hasShapeData != true) {
      await fetchShapes(routeId);
    }

    // 2. Get most-common GeoPath for the route from database
    List<db.GtfsShapesTableData> geoPathData = await database.gtfsShapesDao.getGeoPath(routeId, direction: direction);

    // 3. Convert Data to LatLng
    List<LatLng> geoPath = geoPathData.map((e) => LatLng(e.latitude, e.longitude)).toList();

    return geoPath;
  }

  Future<DateTime?> fetchVersion() async {
    // 1. Get from GTFS Asset database, if it exists
    DateTime? version = await database.gtfsAssetsDao.getGtfsAssetDate(id: "version");

    // 2. If not, get from API
    if (version == null) {
      var jsonVersion = await gtfsApi.version();
      DateTime? gtfsVersion = DateTime.tryParse(jsonVersion["version"]);

      if (gtfsVersion != null) {
        // 3. Add to database
        var dbAsset = database.gtfsAssetsDao.createGtfsAssetCompanion(id: "version", dateModified: gtfsVersion);
        database.gtfsAssetsDao.addGtfsAsset(dbAsset);
      }

      version = await database.gtfsAssetsDao.getGtfsAssetDate(id: "version");
    }

    print(version);
    return version;
  }
}