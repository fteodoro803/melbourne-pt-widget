import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension DirectionHelpers on Database {
  DirectionsTableCompanion createDirectionCompanion(
      {required int id, required String name, required String description}) {
    return DirectionsTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      description: drift.Value(description),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addDirection(int id, String name, String description) async {
    DirectionsTableCompanion direction =
        createDirectionCompanion(id: id, name: name, description: description);
    Database db = Get.find<Database>();
    await db.insertDirection(direction);
  }

  Future<DirectionsTableData?> getDirectionById(int id) async {
    drift.SimpleSelectStatement<$DirectionsTableTable, DirectionsTableData>
        query;
    query = select(directionsTable)..where((d) => d.id.equals(id));
    final result = await query.getSingleOrNull();
    return result;
  }
}
