import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension StopRouteDirectionHelpers on AppDatabase {
  LinkStopRouteDirectionsTableCompanion createStopDirectionsTypeCompanion({required int stopId, required int routeId, required int directionId, int? sequence}) {
    return LinkStopRouteDirectionsTableCompanion(
      stopId: drift.Value(stopId),
      routeId: drift.Value(routeId),
      directionId: drift.Value(directionId),
      sequence: sequence != null ? drift.Value(sequence) : drift.Value.absent(),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addStopRouteDirection({required int stopId, required int routeId, required int directionId, int? sequence}) async {
    LinkStopRouteDirectionsTableCompanion stopDirection = createStopDirectionsTypeCompanion(stopId: stopId, routeId: routeId, directionId: directionId, sequence: sequence);
    AppDatabase db = Get.find<AppDatabase>();
    await db.insertStopRouteDirectionsLink(stopDirection);
  }

  // todo: generate stop sequences in reverse direction
  // get list of directions, and see what's not yet in the list, and then generate by flipping the order
}