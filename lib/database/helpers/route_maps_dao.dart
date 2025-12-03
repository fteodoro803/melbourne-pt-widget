import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'route_maps_dao.g.dart';

@DriftAccessor(tables: [RouteMapsTable])
class RouteMapsDao extends DatabaseAccessor<Database>
    with _$RouteMapsDaoMixin {
  RouteMapsDao(super.db);

  RouteMapsTableCompanion createRouteMap(
      {required int ptvId, required String gtfsId}) {
    return RouteMapsTableCompanion(
      ptvId: Value(ptvId),
      gtfsId: Value(gtfsId),
    );
  }

  /// Adds/Updates a PTV-GTFS route map object to the database.
  Future<void> addRouteMap(RouteMapsTableCompanion routeMap) async {
    await db.mergeUpdate(
        routeMapsTable,
        routeMap,
            (r) =>
        r.ptvId.equals(routeMap.ptvId.value) &
        r.gtfsId.equals(routeMap.gtfsId.value)
    );
  }

  // todo: Sync route Maps
  /// Go through PTV Routes and map to corresponding GTFS Routes
  Future<void> syncRouteMap() async {
    // 1. Go through PTV Routes
    SimpleSelectStatement<$RoutesTableTable, RoutesTableData> ptvQuery;
    ptvQuery = select(routesTable);
    List<RoutesTableData> ptvResult = await ptvQuery.get();

    for (var ptvRoute in ptvResult) {
      // 2. Get GTFS Route from PTV Route
      GtfsRoutesTableData? gtfsRoute = await mapPtvToGtfsRoute(
          ptvRoute.toCompanion(true), ptvRoute.routeTypeId);

      // 3. Map Route IDs between PTV and GTFS
      if (gtfsRoute != null) {
        var routeMap = createRouteMap(ptvId: ptvRoute.id, gtfsId: gtfsRoute.id);
        await addRouteMap(routeMap);
      }
    }
  }

  /// Mapping logic for conversion from PTV Route to GTFS Route
  // todo: Add other cases for metro train and metro bus
  Future<GtfsRoutesTableData?> mapPtvToGtfsRoute(
      RoutesTableCompanion ptvRoute, int routeType) async {
    String name = ptvRoute.name.value;
    String number = ptvRoute.number.value;

    SimpleSelectStatement<$GtfsRoutesTableTable, GtfsRoutesTableData>
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
    var query = select(routeMapsTable)
      ..where((tbl) => tbl.ptvId.equals(ptvRouteId));

    final result = await query.getSingleOrNull();
    return result?.gtfsId;
  }

  Future<int?> convertToPtvRouteId(String gtfsRouteId) async {
    var query = select(routeMapsTable)
      ..where((tbl) => tbl.gtfsId.equals(gtfsRouteId));

    final result = await query.getSingleOrNull();
    return result?.ptvId;
  }
}