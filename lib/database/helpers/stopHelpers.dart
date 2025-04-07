import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension StopHelpers on AppDatabase {
  Future<StopsCompanion> createStopCompanion({required int id, required String name, required int routeTypeId, required double latitude, required double longitude})
  async {
    return StopsCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      routeTypeId: drift.Value(routeTypeId),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addStop(int id, String name, int routeTypeId, double latitude, double longitude) async {
    StopsCompanion stop = await createStopCompanion(id: id, name: name, routeTypeId: routeTypeId, latitude: latitude, longitude: longitude);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertStop(stop);
  }

  // todo: function for distance from Stop
}