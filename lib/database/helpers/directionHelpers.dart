import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';


extension DirectionHelpers on AppDatabase {
  Future<DirectionsTableCompanion> createDirectionCompanion({required int id, required String name, required String description,})
  async {
    return DirectionsTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      description: drift.Value(description),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addDirection(int id, String name, String description) async {
    DirectionsTableCompanion direction = await createDirectionCompanion(id: id, name: name, description: description);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertDirection(direction);
  }
}