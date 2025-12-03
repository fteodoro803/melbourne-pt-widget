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

// todo: generate stop sequences in reverse direction
// get list of directions, and see what's not yet in the list, and then generate by flipping the order
}