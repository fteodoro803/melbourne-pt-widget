import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension RouteStopHelpers on AppDatabase {
  Future<LinkRouteStopsTableCompanion> createRouteStopCompanion({required int routeId, required int stopId})
  async {
    return LinkRouteStopsTableCompanion(
      routeId: drift.Value(routeId),
      stopId: drift.Value(stopId),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRouteStop(int routeId, int stopId) async {
    LinkRouteStopsTableCompanion routeStop = await createRouteStopCompanion(routeId: routeId, stopId: stopId);
    AppDatabase db = Get.find<AppDatabase>();
    await db.insertRouteStopLink(routeStop);
  }

  Future<List<RoutesTableData>> getRoutesFromStop(int stopId) async {
    // Join routes to routeStops, where their route ids are equal
    final query = select(routesTable).join([
      drift.innerJoin(
        linkRouteStopsTable,
        linkRouteStopsTable.routeId.equalsExp(routesTable.id),
      )
    ])
      ..where(linkRouteStopsTable.stopId.equals(stopId));  // filter results where stop id matches

    // Convert the joined results to Route objects
    final rows = await query.get();
    final results = rows.map((row) {
      return row.readTable(routesTable);
    }).toList();

    return results;
  }

  // /// Returns a list of stops, in order of sequence.
  // Future<List<StopsTableData>> getStopsOnRoute(int routeId) async {
  //   // Join stops to routes via routeStops junction table
  //   final query = select(stopsTable).join([
  //     drift.innerJoin(
  //         linkRouteStopsTable,
  //         linkRouteStopsTable.stopId.equalsExp(stopsTable.id),
  //     ),
  //     drift.innerJoin(
  //         routesTable,
  //         linkRouteStopsTable.routeId.equalsExp(routesTable.id),
  //     ),
  //   ])
  //       ..where(linkRouteStopsTable.routeId.equals(routeId))
  //       // ..orderBy([drift.OrderingTerm.asc(stopsTable.sequence)])   // todo: Order by sequence
  //   ;
  //
  //   // Convert the joined results to Stop objects
  //   final rows = await query.get();
  //   final results = rows.map((row) {
  //     return row.readTable(stopsTable);
  //   }).toList();
  //
  //   return results;
  // }
}