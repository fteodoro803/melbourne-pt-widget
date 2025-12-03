import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'trips_dao.g.dart';

@DriftAccessor(tables: [TripsTable])
class TripsDao extends DatabaseAccessor<Database>
    with _$TripsDaoMixin {
  TripsDao(super.db);

  TripsTableCompanion createTripCompanion(
      {required String uniqueId,
        required int routeTypeId,
        required int routeId,
        required int stopId,
        required int directionId,
        int? index}) {
    return TripsTableCompanion(
      uniqueId: Value(uniqueId),
      routeTypeId: Value(routeTypeId),
      routeId: Value(routeId),
      stopId: Value(stopId),
      directionId: Value(directionId),
      index: index != null ? Value(index) : Value.absent(),
    );
  }

  // Transport Functions
  Future<void> _insertTrip(TripsTableCompanion transport) async {
    await db.mergeUpdate(tripsTable, transport,
            (t) => t.uniqueId.equals(transport.uniqueId.value));
  }

  Future<void> addTrip(
      {required String uniqueId,
        required int routeTypeId,
        required int routeId,
        required int stopId,
        required int directionId,
        int? index}) async {
    TripsTableCompanion transport = createTripCompanion(
        uniqueId: uniqueId,
        routeTypeId: routeTypeId,
        routeId: routeId,
        stopId: stopId,
        directionId: directionId,
        index: index);
    await _insertTrip(transport);
  }

  Future<void> removeTrip(String uniqueId) async {
    await (delete(tripsTable)..where((t) => t.uniqueId.equals(uniqueId))).go();
  }

  /// Returns the Transport list in ascending index order
  Future<List<TripsTableData>> getTrips() async {
    SimpleSelectStatement<$TripsTableTable, TripsTableData> query;
    query = select(tripsTable)
      ..orderBy([(t) => OrderingTerm(expression: t.index)]);
    var result = await query.get();
    return result;
  }

  Future<bool> isTripInDatabase(String id) async {
    SimpleSelectStatement<$TripsTableTable, TripsTableData> query;
    query = select(tripsTable)..where((t) => t.uniqueId.equals(id));
    var result = await query.getSingleOrNull();

    return result != null ? true : false;
  }
}