import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'link_stop_route_types_dao.g.dart';

@DriftAccessor(tables: [LinkStopRouteTypesTable])
class LinkStopRouteTypesDao extends DatabaseAccessor<Database>
    with _$LinkStopRouteTypesDaoMixin {
  LinkStopRouteTypesDao(super.db);

  LinkStopRouteTypesTableCompanion createStopRouteTypeCompanion(
      {required int stopId, required int routeTypeId}) {
    return LinkStopRouteTypesTableCompanion(
      stopId: Value(stopId),
      routeTypeId: Value(routeTypeId),
      lastUpdated: Value(DateTime.now()),
    );
  }

  Future<void> _insertStopRouteTypeLink(
      LinkStopRouteTypesTableCompanion stopRouteType) async {
    await db.mergeUpdate(
        linkStopRouteTypesTable,
        stopRouteType,
            (s) =>
        s.stopId.equals(stopRouteType.stopId.value) &
        s.routeTypeId.equals(stopRouteType.routeTypeId.value));
  }

  Future<void> addStopRouteType(int stopId, int routeTypeId) async {
    LinkStopRouteTypesTableCompanion stopRouteType =
    createStopRouteTypeCompanion(stopId: stopId, routeTypeId: routeTypeId);
    await _insertStopRouteTypeLink(stopRouteType);
  }
}