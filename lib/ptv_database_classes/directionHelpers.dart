import 'package:drift/drift.dart' as drift;
import '../database.dart';
import 'package:get/get.dart';

extension DirectionHelpers on AppDatabase {
  Future<DirectionsCompanion> createDirectionCompanion({required int id, required String name, required String description,})
  async {
    return DirectionsCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      description: drift.Value(description),
    );
  }

  Future<void> addDirection(int id, String name, String description) async {
    DirectionsCompanion direction = await createDirectionCompanion(id: id, name: name, description: description);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertDirection(direction);
  }
}