import 'package:flutter_project/database/helpers/direction_helpers.dart';
import 'package:flutter_project/database/helpers/link_route_directions_helpers.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/services/ptv/ptv_base_service.dart';
import 'package:get/get.dart';

class PtvDirectionService extends PtvBaseService {
  /// Fetches directions for a given route.
  /// Uses data from either the database or PTV API, preferring the database.
  Future<List<Direction>> fetchDirections(int routeId) async {
    List<Direction> directionList = [];

    // 1. Check if directions data exists in database
    // 2a. If it does, set directionList to the retrieved data
    final dbDirectionsList = await database.getDirectionsByRoute(routeId);
    if (dbDirectionsList.isNotEmpty) {
      directionList = dbDirectionsList.map(Direction.fromDb).toList();
    }

    // 2b. Fetch data from the API
    else {
      var data = await apiService.directions(routeId.toString());

      // Early Exit
      if (data == null) {
        handleNullResponse("fetchDirections");
        return [];
      }

      // 3. Populate direction list
      for (var direction in data["directions"]) {
        int routeId = direction["route_id"];
        Direction newDirection = Direction.fromApi(direction);
        directionList.add(newDirection);

        // 4. Add to database
        await database.addDirection(
            newDirection.id, newDirection.name, newDirection.description);
        await database.addRouteDirection(
            routeId: routeId, directionId: newDirection.id);
      }
    }

    return directionList;
  }

  /// Get a route's opposite direction.
  /// Assumes that there at most 2 directions to a route.
  // todo: maybe this can be implemented in a domain class (trip?)
  Future<Direction?> getReverse(
      {required Route route, required Direction direction}) async {
    // 1. Fetch directions
    List<Direction> directions = await fetchDirections(route.id);

    // 2. Get the other direction (if it exists)
    if (directions.length == 2) {
      return directions.firstWhereOrNull((d) => d.id != direction.id);
    }

    return null;
  }
}
