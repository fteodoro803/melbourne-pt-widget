import 'package:drift/drift.dart' as drift;
import '../database.dart';
import 'package:get/get.dart';

extension RouteTypeHelpers on AppDatabase {
  Future<RouteTypesCompanion> createRouteTypeCompanion({required int id, required String name})
  async {
    return RouteTypesCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRouteType(int id, String name) async {
    RouteTypesCompanion routeType = await createRouteTypeCompanion(id: id, name: name);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertRouteType(routeType);
  }
}