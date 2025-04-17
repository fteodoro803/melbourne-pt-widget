import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';


extension DirectionHelpers on AppDatabase {
  Future<DirectionsTableCompanion> createDirectionCompanion({required int id, required String name, required String description, required int routeId})
  async {
    return DirectionsTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      description: drift.Value(description),
      routeId: drift.Value(routeId),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addDirection(int id, String name, String description, int routeId) async {
    DirectionsTableCompanion direction = await createDirectionCompanion(id: id, name: name, description: description, routeId: routeId);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertDirection(direction);
  }

  Future<List<DirectionsTableData>> getDirectionsByRoute(int routeId) async {
    drift.SimpleSelectStatement<$DirectionsTableTable, DirectionsTableData> query;
    query = select(directionsTable)
      ..where((tbl) => tbl.routeId.equals(routeId));

    final result = await query.get();
    return result;
  }
}