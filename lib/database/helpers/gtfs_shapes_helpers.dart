import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

extension GtfsShapeHelpers on Database {
  GtfsShapesTableCompanion createGeoPathCompanion(
      {required String id,
      required double latitude,
      required double longitude,
      required int sequence}) {
    return GtfsShapesTableCompanion(
      id: drift.Value(id),
      sequence: drift.Value(sequence),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
    );
  }

  Future<void> addGtfsShapes(
      {required List<GtfsShapesTableCompanion> geoPath}) async {
    await batchInsert(gtfsShapesTable, geoPath);
  }

  /// Gets general GeoPath of a Route
  Future<List<GtfsShapesTableData>> getGeoPath(String gtfsRouteId,
      {String? direction}) async {
    // 1. Find Trips with a matching Route ID
    var tripsQuery;
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
      ..orderBy([(t) => drift.OrderingTerm.asc(t.sequence)]);
    final geoPath = await geoPathQuery.get();

    return geoPath;
  }

  Future<void> clearShapesTable() async {
    await delete(gtfsShapesTable).go();
  }
}
