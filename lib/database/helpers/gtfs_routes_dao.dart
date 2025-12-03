import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'gtfs_routes_dao.g.dart';

@DriftAccessor(tables: [GtfsRoutesTable])
class GtfsRoutesDao extends DatabaseAccessor<Database>
    with _$GtfsRoutesDaoMixin {
  GtfsRoutesDao(super.db);

  GtfsRoutesTableCompanion createGtfsRouteCompanion(
      {required String routeId,
        required String shortName,
        required String longName}) {
    return GtfsRoutesTableCompanion(
      id: Value(routeId),
      shortName: Value(shortName),
      longName: Value(longName),
    );
  }

  Future<void> _insertGtfsRoute(GtfsRoutesTableCompanion route) async {
    await db.mergeUpdate(
        gtfsRoutesTable, route, (r) => r.id.equals(route.id.value));
  }

  Future<void> addGtfsRoute(
      {required String id,
        required String shortName,
        required String longName}) async {
    GtfsRoutesTableCompanion route = createGtfsRouteCompanion(
        routeId: id, shortName: shortName, longName: longName);
    await _insertGtfsRoute(route);
  }

  Future<List<GtfsRoutesTableData>> getGtfsRoutes() async {
    var query = select(gtfsRoutesTable);
    var result = await query.get();

    return result;
  }

  Future<void> clearGtfsRouteTable() async {
    await delete(gtfsRoutesTable).go();
  }
}