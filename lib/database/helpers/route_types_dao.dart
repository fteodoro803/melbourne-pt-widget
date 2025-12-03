import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'route_types_dao.g.dart';

@DriftAccessor(tables: [RouteTypesTable])
class RouteTypesDao extends DatabaseAccessor<Database>
    with _$RouteTypesDaoMixin {
  RouteTypesDao(super.db);

  RouteTypesTableCompanion createRouteTypeCompanion(
      {required int id, required String name}) {
    return RouteTypesTableCompanion(
      id: Value(id),
      name: Value(name),
      lastUpdated: Value(DateTime.now()),
    );
  }

  /// Adds/Updates a Route Type to the database.
  Future<void> addRouteType(RouteTypesTableCompanion routeType) async {
    await db.mergeUpdate(
        routeTypesTable, routeType, (r) => r.id.equals(routeType.id.value));  }

  /// Gets all route types offered by PTV from the database.
  Future<List<RouteTypesTableData>> getRouteTypes() async {
    var query = select(routeTypesTable);
    final result = await query.get();
    return result;
  }
}