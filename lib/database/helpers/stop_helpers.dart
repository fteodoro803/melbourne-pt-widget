import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension StopHelpers on AppDatabase {
  StopsTableCompanion createStopCompanion({required int id, required String name, required double latitude, required double longitude, String? landmark, String? suburb, String? zone})
  {
    return StopsTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      // routeTypeId: drift.Value(routeTypeId),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
      landmark: landmark != null ? drift.Value(landmark) : drift.Value.absent(),
      suburb: suburb != null ? drift.Value(suburb) : drift.Value.absent(),
      zone: zone != null ? drift.Value(zone) : drift.Value.absent(),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  /// Adds a stop to the database.
  Future<void> addStop({required int id, required String name, required double latitude, required double longitude, String? landmark, String? suburb, String? zone}) async {
    StopsTableCompanion stop = createStopCompanion(id: id, name: name, latitude: latitude, longitude: longitude, landmark: landmark, suburb: suburb, zone: zone);
    await insertStop(stop);
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