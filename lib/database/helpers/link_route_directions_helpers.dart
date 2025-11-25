import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension RouteDirectionHelpers on Database {
  LinkRouteDirectionsTableCompanion createRouteDirectionsTypeCompanion(
      {required int routeId, required int directionId}) {
    return LinkRouteDirectionsTableCompanion(
      routeId: drift.Value(routeId),
      directionId: drift.Value(directionId),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRouteDirection(
      {required int routeId, required int directionId}) async {
    LinkRouteDirectionsTableCompanion routeDirection =
        createRouteDirectionsTypeCompanion(
            routeId: routeId, directionId: directionId);
    Database db = Get.find<Database>();
    await db.insertRouteDirectionLink(routeDirection);
  }

  Future<List<DirectionsTableData>> getDirectionsByRoute(int routeId) async {
    // 1. Join directions and routeDirections table
    final query = select(directionsTable).join([
      drift.innerJoin(
        linkRouteDirectionsTable,
        linkRouteDirectionsTable.directionId.equalsExp(directionsTable.id),
      )
    ])
      ..where(linkRouteDirectionsTable.routeId.equals(routeId));

    // 2. Convert the joined results to list of Direction objects
    final rows = await query.get();
    final results = rows.map((row) {
      return row.readTable(directionsTable);
    }).toList();

    return results;
  }
}
