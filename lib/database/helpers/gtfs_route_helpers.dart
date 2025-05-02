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

  // todo: move this function to a ptv-gtfs route map helper
  // todo: add trains and buses
  Future<GtfsRoutesTableData?> getGtfsRouteFromPtvRoute(RoutesTableCompanion ptvRoute, String routeType) async {
    String name = ptvRoute.name.value;
    String number = ptvRoute.number.value;
    
    drift.SimpleSelectStatement<$GtfsRoutesTableTable, GtfsRoutesTableData> query;
    if (routeType == "tram") {
      query = select(gtfsRoutesTable)
        ..where((tbl) => tbl.shortName.equals(number));
    }
    else {
      query = select(gtfsRoutesTable);
    }

    final result = await query.getSingleOrNull();
    return result;
  }
}