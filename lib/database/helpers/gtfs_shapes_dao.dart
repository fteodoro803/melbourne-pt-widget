import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'gtfs_shapes_dao.g.dart';

@DriftAccessor(tables: [GtfsShapesTable, GtfsTripsTable])
class GtfsShapesDao extends DatabaseAccessor<Database>
    with _$GtfsShapesDaoMixin {
  GtfsShapesDao(super.db);

  GtfsShapesTableCompanion createGtfsShapeCompanion(
      {required String id,
        required double latitude,
        required double longitude,
        required int sequence}) {
    return GtfsShapesTableCompanion(
      id: Value(id),
      sequence: Value(sequence),
      latitude: Value(latitude),
      longitude: Value(longitude),
    );
  }

  /// Batch inserts a list of GTFS Shapes to the database.
  Future<void> addGtfsShapes(
      {required List<GtfsShapesTableCompanion> geoPath}) async {
    await db.batchInsert(gtfsShapesTable, geoPath);
  }

  // Trip data is needed for this to function
  Future<List<GtfsShapesTableData>> getGtfsShapes(String routeId) async {
    // 1. Get distinct shape ids for the route
    var tripQuery = select(gtfsTripsTable)
      ..where((tbl) => tbl.routeId.equals(routeId));
    List<String> tripResult = await tripQuery.map((row) => row.shapeId).get();  // Get all shape ids
    List<String> shapeIds = tripResult.toSet().toList();    // Convert to distinct ids

    // 2. Get shape ids and accumulate in a list
    var shapeQuery = select(gtfsShapesTable)
      ..where((tbl) => (tbl.id.isIn(shapeIds)));
    var shapeResult = await shapeQuery.get();

    return shapeResult;
  }

  /// Gets general GeoPath of a Route
  Future<List<GtfsShapesTableData>> getGeoPath(String gtfsRouteId,
      {String? direction}) async {
    // 1. Find Trips with a matching Route ID
    SimpleSelectStatement<$GtfsTripsTableTable, GtfsTripsTableData> tripsQuery;
    if (direction != null && direction.isNotEmpty) {
      tripsQuery = select(gtfsTripsTable)
        ..where((tbl) =>
        tbl.routeId.equals(gtfsRouteId) &
        tbl.tripHeadsign.equals(direction));
    } else {
      tripsQuery = select(gtfsTripsTable)
        ..where((tbl) => tbl.routeId.equals(gtfsRouteId));
    }
    final List<GtfsTripsTableData> trips = await tripsQuery.get();

    if (trips.isEmpty) {
      return [];
    }

    // 2. Find the most-used GeoPath (shape ID)
    // count occurrences of a shape/path
    Map<String, int> counter = {};
    for (var trip in trips) {
      counter[trip.shapeId] = (counter[trip.shapeId] ?? 0) + 1;
    }

    // set highest-occurring shape as the "general" shapeId
    String shapeId = "";
    int highestCount = 0;
    counter.forEach((shape, count) {
      if (count >= highestCount) {
        shapeId = shape;
        highestCount = count;
      }
    });

    // 3. Get GeoPaths
    final geoPathQuery = select(gtfsShapesTable)
      ..where((tbl) => tbl.id.equals(shapeId))
      ..orderBy([(t) => OrderingTerm.asc(t.sequence)]);
    final geoPath = await geoPathQuery.get();

    return geoPath;
  }

  /// Checks if there is Shape data for the specified route
  Future<bool> gtfsShapeHasData(String routeId) async {
    var query = select(gtfsTripsTable)
      ..where((tbl) => tbl.routeId.equals(routeId))
      ..limit(1);
    var result = await query.getSingleOrNull();

    if (result != null) {
      return true;
    }
    else {
      return false;
    }
  }

  Future<void> clearShapesTable() async {
    await delete(gtfsShapesTable).go();
  }
}