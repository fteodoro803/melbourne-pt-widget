import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension RouteTypeHelpers on AppDatabase {
  Future<RouteTypesTableCompanion> createRouteTypeCompanion({required int id, required String name})
  async {
    return RouteTypesTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  /// Adds a route type to the database
  Future<void> addRouteType(int id, String name) async {
    RouteTypesTableCompanion routeType = await createRouteTypeCompanion(id: id, name: name);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertRouteType(routeType);
  }

  /// Gets all route types offered by PTV from the database.
  Future<List<RouteTypesTableData>> getRouteTypes() async {
    var query = select(routeTypesTable);
    final result = await query.get();
    return result;
  }
}