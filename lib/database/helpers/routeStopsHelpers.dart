import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension RouteStopHelpers on AppDatabase {
  Future<RouteStopsTableCompanion> createRouteStopCompanion({required int routeId, required int stopId})
  async {
    return RouteStopsTableCompanion(
      routeId: drift.Value(routeId),
      stopId: drift.Value(stopId),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRouteStop(int routeId, int stopId) async {
    RouteStopsTableCompanion routeStop = await createRouteStopCompanion(routeId: routeId, stopId: stopId);
    AppDatabase db = Get.find<AppDatabase>();
    await db.insertRouteStopLink(routeStop);
  }

  Future<List<RoutesTableData>> getRoutesFromStop(int stopId) async {
    // Join routes to routeStops, where their route ids are equal
    final query = select(routesTable).join([
      drift.innerJoin(
        routeStopsTable,
        routeStopsTable.routeId.equalsExp(routesTable.id),
      )
    ])
      ..where(routeStopsTable.stopId.equals(stopId));  // filter results where stop id matches

    // Convert the joined results to Route objects
    final rows = await query.get();
    final results = rows.map((row) {
      return row.readTable(routesTable);
    }).toList();

    return results;
  }


  // todo: get stops for a route
}