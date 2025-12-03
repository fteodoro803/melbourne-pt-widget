import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'directions_dao.g.dart';

@DriftAccessor(tables: [DirectionsTable])
class DirectionsDao extends DatabaseAccessor<Database>
    with _$DirectionsDaoMixin {
  DirectionsDao(super.db);

  DirectionsTableCompanion createDirectionCompanion(
      {required int id, required String name, required String description}) {
    return DirectionsTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      lastUpdated: Value(DateTime.now()),
    );
  }

  /// Adds/Updates a direction to the database.
  Future<void> addDirection(DirectionsTableCompanion direction) async {
    await db.mergeUpdate(
        directionsTable, direction, (d) => d.id.equals(direction.id.value));
  }

  Future<DirectionsTableData?> getDirectionById(int id) async {
    SimpleSelectStatement<$DirectionsTableTable, DirectionsTableData> query;
    query = select(directionsTable)..where((d) => d.id.equals(id));
    final result = await query.getSingleOrNull();
    return result;
  }
}