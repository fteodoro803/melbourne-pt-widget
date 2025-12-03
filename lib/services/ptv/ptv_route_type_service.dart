import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/services/ptv/ptv_base_service.dart';

class PtvRouteTypeService extends PtvBaseService {
  /// Fetches all route types offered by PTV from the database.
  /// If no route type data is in database, it fetches from the PTV API and stores it to database.  // todo: get from database first, preferring database
  Future<List<String>> fetchRouteTypes() async {
    List<String> routeTypes = [];

    // 1a. If data exists in database, adds that data to routeTypes list
    final dbRouteTypesList = await database.routeTypesDao.getRouteTypes();
    if (dbRouteTypesList.isNotEmpty) {
      routeTypes = dbRouteTypesList.map((rt) => rt.name).toList();
    }

    // 1b. If data doesn't exist in database, fetches from API and adds it to database
    else {
      var data = await apiService.routeTypes();

      // Early exit: Empty response
      if (data == null) {
        handleNullResponse("fetchRouteTypes");
        return [];
      }

      // 2. Populating RouteTypes list
      for (var entry in data["route_types"]) {
        int id = entry["route_type"];
        RouteType newRouteType = RouteType.fromId(id);
        routeTypes.add(newRouteType.name);

        // 3. Add to database
        await database.routeTypesDao.addRouteType(newRouteType.id, newRouteType.name);
      }
    }

    return routeTypes;
  }
}
