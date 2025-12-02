import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GtfsRouteHelpers on Database {
  GtfsRoutesTableCompanion createGtfsRouteCompanion(
      {required String routeId,
      required String shortName,
      required String longName}) {
    return GtfsRoutesTableCompanion(
      id: drift.Value(routeId),
      shortName: drift.Value(shortName),
      longName: drift.Value(longName),
    );
  }

  Future<void> addGtfsRoute(
      {required String id,
      required String shortName,
      required String longName}) async {
    GtfsRoutesTableCompanion route = createGtfsRouteCompanion(
        routeId: id, shortName: shortName, longName: longName);
    await insertGtfsRoute(route);
  }

  Future<List<GtfsRoutesTableData>> getGtfsRoutes() async {
    drift.SimpleSelectStatement<$GtfsRoutesTableTable, GtfsRoutesTableData> query;
    query = select(gtfsRoutesTable);
    var result = await query.get();

    return result;
  }

  Future<void> clearGtfsRouteTable() async {
    await delete(gtfsRoutesTable).go();
  }
}
