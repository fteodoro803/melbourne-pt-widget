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
      sequence: sequence != null ? drift.Value(sequence) : drift.Value.absent(),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  /// Adds a stop to the database.
  Future<void> addStop(int id, String name, double latitude, double longitude, {int? sequence}) async {
    StopsTableCompanion stop = await createStopCompanion(id: id, name: name, latitude: latitude, longitude: longitude, sequence: sequence);
    insertStop(stop);
  }

  // todo: function for distance from Stop
}