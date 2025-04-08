import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension RouteStopHelpers on AppDatabase {
  Future<RouteStopsCompanion> createRouteStopCompanion({required int routeId, required int stopId})
  async {
    return RouteStopsCompanion(
      routeId: drift.Value(routeId),
      stopId: drift.Value(stopId),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRouteStop(int routeId, int stopId) async {
    RouteStopsCompanion routeStop = await createRouteStopCompanion(routeId: routeId, stopId: stopId);
    AppDatabase db = Get.find<AppDatabase>();
    await db.insertRouteStopLink(routeStop);
  }

  Future<List<Route>> getRoutesFromStop(int stopId) async {
    // Join routes to routeStops, where their route ids are equal
    final query = select(routes).join([
      drift.innerJoin(
        routeStops,
        routeStops.routeId.equalsExp(routes.id),
      )
    ])
      ..where(routeStops.stopId.equals(stopId));  // filter results where stop id matches

    // Convert the joined results to Route objects
    final rows = await query.get();
    final results = rows.map((row) {
      return row.readTable(routes);
    }).toList();

    return results;
  }


  // todo: get stops for a route
}