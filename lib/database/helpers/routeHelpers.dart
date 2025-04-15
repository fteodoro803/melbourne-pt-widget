import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

/// Represents the colours a route can have.
class Colours {
  final String colour;
  final String textColour;

  const Colours(this.colour, this.textColour);
}

extension RouteHelpers on AppDatabase {
  Future<RoutesTableCompanion> createRouteCompanion({required int id, required String name, required String number, required int routeTypeId, required String gtfsId, required String status})
  async {
    AppDatabase db = Get.find<AppDatabase>();
    String? routeType = await db.getRouteTypeNameFromRouteTypeId(routeTypeId);

    return RoutesTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      number: drift.Value(number),
      routeTypeId: drift.Value(routeTypeId),
      gtfsId: drift.Value(gtfsId),
      status: drift.Value(status),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRoute(int id, String name, String number, int routeTypeId, String gtfsId, String status) async {
    RoutesTableCompanion route = await createRouteCompanion(id: id, name: name, number: number, routeTypeId: routeTypeId, gtfsId: gtfsId, status: status);
    AppDatabase db = Get.find<AppDatabase>();
    await db.insertRoute(route);
  }

  /// Gets route according to id.
  Future<RoutesTableData?> getRouteById(int id) async {
    drift.SimpleSelectStatement<$RoutesTableTable, RoutesTableData> query;
    query = select(routesTable)
      ..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result;
  }

  /// Gets routes according to name.
  Future<List<RoutesTableData>> getRoutesByName({String? search, int? routeType}) async {
    AppDatabase db = Get.find<AppDatabase>();

    drift.SimpleSelectStatement<$RoutesTableTable, RoutesTableData> query;
    if (search != null && search.isNotEmpty && routeType != null) {
      query = db.select(db.routesTable)
      ..where((tbl) => tbl.name.contains(search) & tbl.routeTypeId.equals(routeType));
    }
    else if (routeType != null) {
      query = db.select(db.routesTable)
        ..where((tbl) => tbl.routeTypeId.equals(routeType));
    }
    else if (search != null && search.isNotEmpty) {
      query = db.select(db.routesTable)
        ..where((tbl) => tbl.name.contains(search));
    }
    else {
      query = db.select(db.routesTable);
    }

    final result = await query.get();
    return result;
  }
}