import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GeoPathHelpers on AppDatabase {
  GeoPathsTableCompanion createGeoPathCompanion({required String id, required double latitude, required double longitude, required int sequence})
  {
    return GeoPathsTableCompanion(
      id: drift.Value(id),
      sequence: drift.Value(sequence),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
    );
  }

  Future<void> addGeoPaths({required List<GeoPathsTableCompanion> geoPath}) async {
    await batchInsert(geoPathsTable, geoPath);
  }

  /// Gets general GeoPath of a Route
  Future<List<GeoPathsTableData>> getGeoPath(String gtfsRouteId) async {
    // 1. Find Trips with a matching Route ID
    final tripsQuery = select(gtfsTripsTable)
      ..where((tbl) => tbl.routeId.equals(gtfsRouteId));
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

    // 2. Get GeoPaths
    final geoPathQuery = select(geoPathsTable)
      ..where((tbl) => tbl.id.equals(shapeId))
      ..orderBy([(t) => drift.OrderingTerm.asc(t.sequence)]);
    final geoPath = await geoPathQuery.get();

    return geoPath;
  }

  // todo: fetch geopath specified to a trip
}