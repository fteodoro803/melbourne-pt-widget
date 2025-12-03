import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'routes_dao.g.dart';

/// Represents the colours a route can have.
class Colours {
  final String colour;
  final String textColour;

  const Colours(this.colour, this.textColour);
}

@DriftAccessor(tables: [RoutesTable])
class RoutesDao extends DatabaseAccessor<Database>
    with _$RoutesDaoMixin {
  RoutesDao(super.db);

  RoutesTableCompanion createRouteCompanion(
      {required int id,
        required String name,
        required String number,
        required int routeTypeId,
        required String status}) {

    return RoutesTableCompanion(
      id: Value(id),
      name: Value(name),
      number: Value(number),
      routeTypeId: Value(routeTypeId),
      status: Value(status),
      lastUpdated: Value(DateTime.now()),
    );
  }

  /// Adds/Updates a Route to the database.
  Future<void> addRoute(RoutesTableCompanion route) async {
    await db.mergeUpdate(routesTable, route, (r) => r.id.equals(route.id.value));
  }

  /// Gets all routes in database.
  Future<List<RoutesTableData>> getRoutes(int? routeType) async {
    SimpleSelectStatement<$RoutesTableTable, RoutesTableData> query;

    if (routeType != null) {
      query = select(routesTable)
        ..where((tbl) => tbl.routeTypeId.equals(routeType));
    } else {
      query = select(routesTable);
    }

    final result = await query.get();
    return result;
  }

  /// Gets route according to id.
  Future<RoutesTableData?> getRouteById(int id) async {
    SimpleSelectStatement<$RoutesTableTable, RoutesTableData> query;
    query = select(routesTable)..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result;
  }

  /// Gets routes according to name.
  Future<List<RoutesTableData>> getRoutesByName(
      {String? search, int? routeType}) async {

    SimpleSelectStatement<$RoutesTableTable, RoutesTableData> query;
    if (search != null && search.isNotEmpty && routeType != null) {
      query = select(routesTable)
        ..where((tbl) =>
        tbl.name.contains(search) & tbl.routeTypeId.equals(routeType));
    } else if (routeType != null) {
      query = select(routesTable)
        ..where((tbl) => tbl.routeTypeId.equals(routeType));
    } else if (search != null && search.isNotEmpty) {
      query = select(routesTable)
        ..where((tbl) => tbl.name.contains(search));
    } else {
      query = select(routesTable);
    }

    final result = await query.get();
    return result;
  }
}