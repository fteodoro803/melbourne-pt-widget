import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension StopHelpers on AppDatabase {
  Future<StopsTableCompanion> createStopCompanion({required int id, required String name, required double latitude, required double longitude, int? sequence})
  async {
    return StopsTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      // routeTypeId: drift.Value(routeTypeId),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      sequence: drift.Value(sequence),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addStop(int id, String name, double latitude, double longitude, {int? sequence}) async {
    StopsTableCompanion stop = await createStopCompanion(id: id, name: name, latitude: latitude, longitude: longitude, sequence: sequence);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertStop(stop);
  }

  // todo: function for distance from Stop
}