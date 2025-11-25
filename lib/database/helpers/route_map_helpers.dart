import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension RouteMapHelpers on Database {
  RouteMapTableCompanion createRouteMap(
      {required int ptvId, required String gtfsId}) {
    return RouteMapTableCompanion(
      ptvId: drift.Value(ptvId),
      gtfsId: drift.Value(gtfsId),
    );
  }

  Future<void> addRouteMap({required int ptvId, required String gtfsId}) async {
    RouteMapTableCompanion route = createRouteMap(ptvId: ptvId, gtfsId: gtfsId);
    await insertRouteMap(route);
  }

  // todo: Sync route Maps
  // Go through PTV Routes and map to corresponding GTFS Routes
  Future<void> syncRouteMap() async {
    // 1. Go through PTV Routes
    drift.SimpleSelectStatement<$RoutesTableTable, RoutesTableData> ptvQuery;
    ptvQuery = select(routesTable);
    List<RoutesTableData> ptvResult = await ptvQuery.get();

    for (var ptvRoute in ptvResult) {
      // 2. Get GTFS Route from PTV Route
      GtfsRoutesTableData? gtfsRoute = await mapPtvToGtfsRoute(
          ptvRoute.toCompanion(true), ptvRoute.routeTypeId);

      // 3. Map Route IDs between PTV and GTFS
      if (gtfsRoute != null) {
        addRouteMap(ptvId: ptvRoute.id, gtfsId: gtfsRoute.id);
      }
    }
  }

  // Mapping logic for conversion from PTV Route to GTFS Route
  // todo: Add other cases for metro train and metro bus
  Future<GtfsRoutesTableData?> mapPtvToGtfsRoute(
      RoutesTableCompanion ptvRoute, int routeType) async {
    String name = ptvRoute.name.value;
    String number = ptvRoute.number.value;

    drift.SimpleSelectStatement<$GtfsRoutesTableTable, GtfsRoutesTableData>
        query;
    if (routeType == 1) {
      // tram
      query = select(gtfsRoutesTable)
        ..where((tbl) => tbl.shortName.equals(number));
    } else {
      // query = select(gtfsRoutesTable);
      return null;
    }

    final result = await query.getSingleOrNull();
    return result;
  }

  Future<String?> convertToGtfsRouteId(int ptvRouteId) async {
    var query = select(routeMapTable)
      ..where((tbl) => tbl.ptvId.equals(ptvRouteId));

    final result = await query.getSingleOrNull();
    return result?.gtfsId;
  }

  Future<int?> convertToPtvRouteId(String gtfsRouteId) async {
    var query = select(routeMapTable)
      ..where((tbl) => tbl.gtfsId.equals(gtfsRouteId));

    final result = await query.getSingleOrNull();
    return result?.ptvId;
  }
}
