import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension StopRouteTypeHelpers on Database {
  LinkStopRouteTypesTableCompanion createStopRouteTypeCompanion(
      {required int stopId, required int routeTypeId}) {
    return LinkStopRouteTypesTableCompanion(
      stopId: drift.Value(stopId),
      routeTypeId: drift.Value(routeTypeId),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addStopRouteType(int stopId, int routeTypeId) async {
    LinkStopRouteTypesTableCompanion stopRouteType =
        createStopRouteTypeCompanion(stopId: stopId, routeTypeId: routeTypeId);
    Database db = Get.find<Database>();
    await db.insertStopRouteTypeLink(stopRouteType);
  }
}
