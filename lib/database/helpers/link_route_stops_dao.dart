import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'link_route_stops_dao.g.dart';

@DriftAccessor(tables: [LinkRouteStopsTable])
class LinkRouteStopsDao extends DatabaseAccessor<Database>
    with _$LinkRouteStopsDaoMixin {
  LinkRouteStopsDao(super.db);

  LinkRouteStopsTableCompanion createRouteStopCompanion(
      {required int routeId, required int stopId}) {
    return LinkRouteStopsTableCompanion(
      routeId: Value(routeId),
      stopId: Value(stopId),
      lastUpdated: Value(DateTime.now()),
    );
  }

  /// Adds/Updates a routeStop to the database.
  Future<void> addRouteStop(LinkRouteStopsTableCompanion routeStop) async {
    await db.mergeUpdate(
        linkRouteStopsTable,
        routeStop,
            (r) =>
        r.routeId.equals(routeStop.routeId.value) &
        r.stopId.equals(routeStop.stopId.value)
    );
  }

  /// Collects all routes that passes by the stop, from the database.
  Future<List<RoutesTableData>> getRoutesFromStop(int stopId) async {
    // 1. Join routes to routeStops, where their route ids are equal
    final query = select(routesTable).join([
      innerJoin(
        linkRouteStopsTable,
        linkRouteStopsTable.routeId.equalsExp(routesTable.id),
      )
    ])
      ..where(linkRouteStopsTable.stopId
          .equals(stopId)); // filter results where stop id matches

    // 2. Convert the joined results to Route objects
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