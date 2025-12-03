import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'gtfs_trips_dao.g.dart';

@DriftAccessor(tables: [GtfsTripsTable])
class GtfsTripsDao extends DatabaseAccessor<Database>
    with _$GtfsTripsDaoMixin {
  GtfsTripsDao(super.db);

  GtfsTripsTableCompanion createGtfsTripCompanion(
      {required String tripId,
        required String routeId,
        required String shapeId,
        required String tripHeadsign,
        required int wheelchairAccessible}) {
    return GtfsTripsTableCompanion(
      id: Value(tripId),
      routeId: Value(routeId),
      shapeId: Value(shapeId),
      tripHeadsign: Value(tripHeadsign),
      wheelchairAccessible: Value(wheelchairAccessible),
    );
  }

  // GTFS Trip Functions
  Future<void> _insertGtfsTrip(GtfsTripsTableCompanion trip) async {
    await db.mergeUpdate(gtfsTripsTable, trip, (t) => t.id.equals(trip.id.value));
  }

  Future<void> addGtfsTrip(
      {required String tripId,
        required String routeId,
        required String tripHeadsign,
        required String shapeId,
        required int wheelchairAccessible}) async {
    GtfsTripsTableCompanion trip = createGtfsTripCompanion(
        tripId: tripId,
        routeId: routeId,
        shapeId: shapeId,
        tripHeadsign: tripHeadsign,
        wheelchairAccessible: wheelchairAccessible);
    await _insertGtfsTrip(trip);
  }

  Future<void> addGtfsTrips(
      {required List<GtfsTripsTableCompanion> trips}) async {
    await db.batchInsert(gtfsTripsTable, trips);
  }

  Future<List<GtfsTripsTableData>> getGtfsTripsByRouteId(
      String gtfsRouteId) async {
    SimpleSelectStatement<$GtfsTripsTableTable, GtfsTripsTableData> query;
    query = select(gtfsTripsTable)
      ..where((tbl) => tbl.routeId.equals(gtfsRouteId));
    var result = await query.get();

    return result;
  }

  Future<Map<String, String>> getShapeIdsHeadsign(String gtfsRouteId) async {
    Map<String, String> routeShapeMap = {};

    // 1. Filter by route ID
    var query = select(gtfsTripsTable)
      ..where((tbl) => tbl.routeId.equals(gtfsRouteId));
    var result = await query.get();

    // 2. Get unique shape IDs
    for (var row in result) {
      routeShapeMap[row.shapeId] = row.tripHeadsign;
    }

    return routeShapeMap;
  }

  /// Checks if there is Trip data for the specified route
  Future<bool> gtfsTripsHasData(String routeId) async {
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

  Future<void> clearGtfsTripsTable() async {
    await delete(gtfsTripsTable).go();
  }
}