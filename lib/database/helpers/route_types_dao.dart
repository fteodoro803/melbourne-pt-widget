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

  // RouteType Functions
  /// Adds a route type to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> _insertRouteType(RouteTypesTableCompanion routeType) async {
    await db.mergeUpdate(
        routeTypesTable, routeType, (r) => r.id.equals(routeType.id.value));
  }

  /// Adds a route type to the database
  Future<void> addRouteType(int id, String name) async {
    RouteTypesTableCompanion routeType =
    createRouteTypeCompanion(id: id, name: name);
    await _insertRouteType(routeType);
  }

  /// Gets all route types offered by PTV from the database.
  Future<List<RouteTypesTableData>> getRouteTypes() async {
    var query = select(routeTypesTable);
    final result = await query.get();
    return result;
  }
}