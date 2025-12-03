import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'link_route_directions_dao.g.dart';

@DriftAccessor(tables: [LinkRouteDirectionsTable])
class LinkRouteDirectionsDao extends DatabaseAccessor<Database>
    with _$LinkRouteDirectionsDaoMixin {
  LinkRouteDirectionsDao(super.db);

  LinkRouteDirectionsTableCompanion createRouteDirectionsTypeCompanion(
      {required int routeId, required int directionId}) {
    return LinkRouteDirectionsTableCompanion(
      routeId: Value(routeId),
      directionId: Value(directionId),
      lastUpdated: Value(DateTime.now()),
    );
  }

  // LinkRouteDirections Functions
  Future<void> _insertRouteDirectionLink(
      LinkRouteDirectionsTableCompanion routeDirection) async {
    await db.mergeUpdate(
        linkRouteDirectionsTable,
        routeDirection,
            (r) =>
        r.routeId.equals(routeDirection.routeId.value) &
        r.directionId.equals(routeDirection.directionId.value));
  }

  Future<void> addRouteDirection(
      {required int routeId, required int directionId}) async {
    LinkRouteDirectionsTableCompanion routeDirection =
    createRouteDirectionsTypeCompanion(
        routeId: routeId, directionId: directionId);
    await _insertRouteDirectionLink(routeDirection);
  }

  Future<List<DirectionsTableData>> getDirectionsByRoute(int routeId) async {
    // 1. Join directions and routeDirections table
    final query = select(directionsTable).join([
      innerJoin(
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