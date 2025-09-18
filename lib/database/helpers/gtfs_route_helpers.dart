import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GtfsRouteHelpers on AppDatabase {
  Future<GtfsRoutesTableCompanion> createGtfsRouteCompanion({required String routeId, required String shortName, required String longName})
  async {
    return GtfsRoutesTableCompanion(
      id: drift.Value(routeId),
      shortName: drift.Value(shortName),
      longName: drift.Value(longName),
    );
  }

  Future<void> addGtfsRoute({required String id, required String shortName, required String longName}) async {
    GtfsRoutesTableCompanion route = await createGtfsRouteCompanion(routeId: id, shortName: shortName, longName: longName);
    await insertGtfsRoute(route);
  }

  Future<void> clearGtfsRouteTable() async {
    await delete(gtfsRoutesTable).go();
  }

}