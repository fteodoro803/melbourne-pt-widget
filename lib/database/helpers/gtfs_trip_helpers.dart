import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GtfsTripHelpers on AppDatabase {
  GtfsTripsTableCompanion createGtfsTripCompanion({required String tripId, required String routeId, required String shapeId, required String tripHeadsign, required int wheelchairAccessible}) {
    return GtfsTripsTableCompanion(
      id: drift.Value(tripId),
      routeId: drift.Value(routeId),
      shapeId: drift.Value(shapeId),
      tripHeadsign: drift.Value(tripHeadsign),
      wheelchairAccessible: drift.Value(wheelchairAccessible),
    );
  }

  Future<void> addGtfsTrip({required String tripId, required String routeId, required String tripHeadsign, required String shapeId, required int wheelchairAccessible}) async {
    GtfsTripsTableCompanion trip = createGtfsTripCompanion(tripId: tripId, routeId: routeId, shapeId: shapeId, tripHeadsign: tripHeadsign, wheelchairAccessible: wheelchairAccessible);
    await insertGtfsTrip(trip);
  }

  Future<void> addGtfsTrips({required List<GtfsTripsTableCompanion> trips}) async {
    await batchInsert(gtfsTripsTable, trips);
  }

  Future<List<GtfsTripsTableData>> getGtfsTripsByRouteId(String gtfsRouteId) async {
    drift.SimpleSelectStatement<$GtfsTripsTableTable, GtfsTripsTableData> query;
    query = select(gtfsTripsTable)..where((tbl) => tbl.routeId.equals(gtfsRouteId));
    var result = await query.get();

    return result;
  }

  // todo: experimental
  Future<Map<String, String>> getShapeIdsHeadsign(String gtfsRouteId) async {
    Map<String, String> routeShapeMap = {};

    // 1. Filter by route ID
    var query = select(gtfsTripsTable)..where((tbl) => tbl.routeId.equals(gtfsRouteId));
    var result = await query.get();

    // 2. Get unique shape IDs
    for (var row in result) {
      routeShapeMap[row.shapeId] = row.tripHeadsign;
    }

    return routeShapeMap;
  }
}