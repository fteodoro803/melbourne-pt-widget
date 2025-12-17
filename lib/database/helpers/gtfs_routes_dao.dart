import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'gtfs_routes_dao.g.dart';

@DriftAccessor(tables: [GtfsRoutesTable])
class GtfsRoutesDao extends DatabaseAccessor<Database>
    with _$GtfsRoutesDaoMixin {
  GtfsRoutesDao(super.db);

  GtfsRoutesTableCompanion createGtfsRouteCompanion(
      {required String id,
        required String shortName,
        String? longName,
        required String colour,
        required String textColour,
        required int routeType,
      }) {
    return GtfsRoutesTableCompanion(
      id: Value(id),
      shortName: Value(shortName),
      longName: longName != null ? Value(longName) : Value.absent(),
      colour: Value(colour),
      textColour: Value(textColour),
      routeType: Value(routeType),
    );
  }

  /// Adds/Updates a GTFS Route to the database.
  Future<void> addGtfsRoute(GtfsRoutesTableCompanion route) async {
    await db.mergeUpdate(
        gtfsRoutesTable, route, (r) => r.id.equals(route.id.value));
  }

  Future<GtfsRoutesTableData?> getRoute(String id) async {
    var query = select(gtfsRoutesTable)..where((r) => r.id.equals(id));
    var result = await query.getSingleOrNull();
    return result;
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