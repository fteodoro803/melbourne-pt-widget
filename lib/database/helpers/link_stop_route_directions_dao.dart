import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'link_stop_route_directions_dao.g.dart';

@DriftAccessor(tables: [LinkStopRouteDirectionsTable])
class LinkStopRouteDirectionsDao extends DatabaseAccessor<Database>
    with _$LinkStopRouteDirectionsDaoMixin {
  LinkStopRouteDirectionsDao(super.db);

  LinkStopRouteDirectionsTableCompanion createStopDirectionsTypeCompanion(
      {required int stopId,
        required int routeId,
        required int directionId,
        int? sequence}) {
    return LinkStopRouteDirectionsTableCompanion(
      stopId: Value(stopId),
      routeId: Value(routeId),
      directionId: Value(directionId),
      sequence: sequence != null ? Value(sequence) : Value.absent(),
      lastUpdated: Value(DateTime.now()),
    );
  }

  /// Adds/Updates a Stop-Route-Direction junction to the database.
  Future<void> addStopRouteDirection(LinkStopRouteDirectionsTableCompanion stopDirection) async {
    await db.mergeUpdate(
        linkStopRouteDirectionsTable,
        stopDirection,
            (s) =>
        s.stopId.equals(stopDirection.stopId.value) &
        s.routeId.equals(stopDirection.routeId.value) &
        s.directionId.equals(stopDirection.directionId.value));  }

  /// Gets Stops of a Route in a Direction in ascending sequence order.
  Future<List<StopsTableData>> getStopRouteDirection({required int routeId, required int directionId}) async {
    List<StopsTableData> stops = [];

    var query = select(linkStopRouteDirectionsTable).join([
      innerJoin(
        stopsTable,
        stopsTable.id.equalsExp(linkStopRouteDirectionsTable.stopId),
      ),
    ])
      ..where(linkStopRouteDirectionsTable.routeId.equals(routeId) & linkStopRouteDirectionsTable.directionId.equals(directionId))
      ..orderBy([OrderingTerm.asc(linkStopRouteDirectionsTable.sequence)]);
    var result = await query.get();

    for (var row in result) {
      var stop = row.readTable(stopsTable);
      // var sequence = row.readTable(linkStopRouteDirectionsTable).sequence;
      stops.add(stop);
    }

    return stops;
  }

// todo: generate stop sequences in reverse direction
// get list of directions, and see what's not yet in the list, and then generate by flipping the order
}