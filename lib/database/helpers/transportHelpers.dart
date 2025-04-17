import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension TransportHelpers on AppDatabase {
  Future<TransportsTableCompanion> createTransportCompanion({required String uniqueId, required int routeTypeId, required int routeId, required int stopId, required int directionId})
  async {
    return TransportsTableCompanion(
      uniqueId: drift.Value(uniqueId),
      routeTypeId: drift.Value(routeTypeId),
      routeId: drift.Value(routeId),
      stopId: drift.Value(stopId),
      directionId: drift.Value(directionId),
    );
  }

  Future<void> addTransport(
      {required String uniqueId, required int routeTypeId, required int routeId,
        required int stopId, required int directionId}) async {
    TransportsTableCompanion transport = await createTransportCompanion(uniqueId: uniqueId, routeTypeId: routeTypeId, routeId: routeId, stopId: stopId, directionId: directionId);
    await insertTransport(transport);
  }

  Future<void> removeTransport(String uniqueId) async {
    await (delete(transportsTable)
      ..where((t) => t.uniqueId.equals(uniqueId))).go();
  }

  Future<List<TransportsTableData>> getTransports() async {
    drift.SimpleSelectStatement<$TransportsTableTable, TransportsTableData> query;
    query = select(transportsTable);
    var result = await query.get();
    return result;
  }

  Future<bool> isTransportInDatabase(String id) async {
    drift.SimpleSelectStatement<$TransportsTableTable, TransportsTableData> query;
    query = select(transportsTable)..where((t) => t.uniqueId.equals(id));
    var result = await query.getSingleOrNull();

    return result != null ? true : false;
  }
}