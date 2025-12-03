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

  /// Adds/Updates a Stop to the database.
  Future<void> addStop(StopsTableCompanion stop) async {
    await db.mergeUpdate(stopsTable, stop, (t) => t.id.equals(stop.id.value));
  }

  Future<StopsTableData?> getStopById(int id) async {
    SimpleSelectStatement<$StopsTableTable, StopsTableData> query;
    query = select(stopsTable)..where((s) => s.id.equals(id));
    final result = await query.getSingleOrNull();
    return result;
  }

  // todo: function for distance from Stop
}