import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension TransportHelpers on Database {
  TripsTableCompanion createTripCompanion(
      {required String uniqueId,
      required int routeTypeId,
      required int routeId,
      required int stopId,
      required int directionId,
      int? index}) {
    return TripsTableCompanion(
      uniqueId: drift.Value(uniqueId),
      routeTypeId: drift.Value(routeTypeId),
      routeId: drift.Value(routeId),
      stopId: drift.Value(stopId),
      directionId: drift.Value(directionId),
      index: index != null ? drift.Value(index) : drift.Value.absent(),
    );
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
    await insertTransport(transport);
  }

  Future<void> removeTransport(String uniqueId) async {
    await (delete(tripsTable)..where((t) => t.uniqueId.equals(uniqueId))).go();
  }

  /// Returns the Transport list in ascending index order
  Future<List<TripsTableData>> getTrips() async {
    drift.SimpleSelectStatement<$TripsTableTable, TripsTableData> query;
    query = select(tripsTable)
      ..orderBy([(t) => drift.OrderingTerm(expression: t.index)]);
    var result = await query.get();
    return result;
  }

  Future<bool> isTripInDatabase(String id) async {
    drift.SimpleSelectStatement<$TripsTableTable, TripsTableData> query;
    query = select(tripsTable)..where((t) => t.uniqueId.equals(id));
    var result = await query.getSingleOrNull();

    return result != null ? true : false;
  }
}
