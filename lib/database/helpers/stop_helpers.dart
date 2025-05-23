import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension StopHelpers on AppDatabase {
  Future<StopsTableCompanion> createStopCompanion({required int id, required String name, required double latitude, required double longitude, int? sequence, String? landmark, String? suburb})
  async {
    return StopsTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      // routeTypeId: drift.Value(routeTypeId),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      sequence: sequence != null ? drift.Value(sequence) : drift.Value.absent(),
      landmark: landmark != null ? drift.Value(landmark) : drift.Value.absent(),
      suburb: suburb != null ? drift.Value(suburb) : drift.Value.absent(),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  /// Adds a stop to the database.
  Future<void> addStop(int id, String name, double latitude, double longitude, {int? sequence, String? landmark, String? suburb}) async {
    StopsTableCompanion stop = await createStopCompanion(id: id, name: name, latitude: latitude, longitude: longitude, sequence: sequence, landmark: landmark, suburb: suburb);
    insertStop(stop);
  }

  Future<StopsTableData?> getStopById(int id) async {
    drift.SimpleSelectStatement<$StopsTableTable, StopsTableData> query;
    query = select(stopsTable)
      ..where((s) => s.id.equals(id));
    final result = await query.getSingleOrNull();
    return result;
  }

  // todo: function for distance from Stop
}