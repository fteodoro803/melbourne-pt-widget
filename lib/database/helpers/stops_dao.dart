import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'stops_dao.g.dart';

@DriftAccessor(tables: [StopsTable])
class StopsDao extends DatabaseAccessor<Database>
    with _$StopsDaoMixin {
  StopsDao(super.db);

  StopsTableCompanion createStopCompanion(
      {required int id,
        required String name,
        required double latitude,
        required double longitude,
        String? landmark,
        String? suburb,
        String? zone}) {
    return StopsTableCompanion(
      id: Value(id),
      name: Value(name),
      // routeTypeId: drift.Value(routeTypeId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      landmark: landmark != null ? Value(landmark) : Value.absent(),
      suburb: suburb != null ? Value(suburb) : Value.absent(),
      zone: zone != null ? Value(zone) : Value.absent(),
      lastUpdated: Value(DateTime.now()),
    );
  }

  /// Adds a stop to the database, if it doesn't already exist.
  /// If it does, update the old stop by merging it with the new one.
  Future<void> _insertStop(StopsTableCompanion stop) async {
    await db.mergeUpdate(stopsTable, stop, (t) => t.id.equals(stop.id.value));
  }

  /// Adds a stop to the database.
  Future<void> addStop(
      {required int id,
        required String name,
        required double latitude,
        required double longitude,
        String? landmark,
        String? suburb,
        String? zone}) async {
    StopsTableCompanion stop = createStopCompanion(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        landmark: landmark,
        suburb: suburb,
        zone: zone);
    await _insertStop(stop);
  }

  Future<StopsTableData?> getStopById(int id) async {
    SimpleSelectStatement<$StopsTableTable, StopsTableData> query;
    query = select(stopsTable)..where((s) => s.id.equals(id));
    final result = await query.getSingleOrNull();
    return result;
  }

  // todo: function for distance from Stop
}