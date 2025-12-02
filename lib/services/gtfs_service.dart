import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/database/helpers/route_map_helpers.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/services/gtfs/gtfs_realtime_service.dart';
import 'package:flutter_project/services/gtfs/gtfs_schedule_service.dart';
import 'package:get/get.dart';

/* GTFS Steps
- Getting GTFS Datasets (GTFS Route, GTFS Shapes)
1. todo: figure this part out (setup a server, OR use github actions) https://claude.ai/chat/b0dad283-a1ad-4c19-81cc-493659c7185d

- Mapping GTFS to PTV (Locations)
1. Get GTFS Routes (route_id)
2. Get GTFS Trips (trip_id, route_id, direction_id)

- todo: GeoPath
1. Get GTFS Shapes (shape_id)
2. Get GTFS Trips(trip_id, shape_id, route_id)
- todo: accurate stops locations
*/

class GtfsService {
  GtfsApiService gtfsApi = GtfsApiService();
  db.Database database = Get.find<db.Database>();
  GtfsRealtimeService realtime = GtfsRealtimeService();
  GtfsScheduleService schedule = GtfsScheduleService();

  /// Adds GTFS Schedule data to database
  // todo: add functionality to skip initialisation if the data is up to date, or files aren't there
  Future<void> initialise() async {
    DateTime startTime = DateTime.now();

    // todo: check if version update needed
    await realtime.fetchGtfsRoutes();

    DateTime endTime = DateTime.now();
    int duration = endTime.difference(startTime).inSeconds;
    print(
        "( gtfs_service.dart -> initialise ) -- finished in $duration seconds");
  }

  Future<String?> convertPtvRouteToGtfs(Route route) async {
    String? gtfsRouteId = await database.convertToGtfsRouteId(route.id);
    return gtfsRouteId;
  }
}
