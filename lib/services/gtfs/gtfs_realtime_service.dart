import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GtfsRealtimeService {
  GtfsApiService gtfsApi = GtfsApiService();
  db.Database database = Get.find<db.Database>();


  /// Returns a list of LatLng objects representing the current positions of trams on a specified route.
  // todo: map ptv routeId to gtfs routeId by name (shortname then longname)
  // todo: edge case, combined routes (501-503)
  Future<List<LatLng>> getTramPositions(int routeId) async {
    List<LatLng> locations = [];
    final feedMessage = await gtfsApi.tramVehiclePositions();

    // 1. Map PTV route ID to GTFS route ID
    String? gtfsRouteId = await database.routeMapsDao.convertToGtfsRouteId(routeId);

    // 2. Get GTFS route IDs associated with the route
    List<db.GtfsTripsTableData>? trips = gtfsRouteId != null
        ? await database.gtfsTripsDao.getGtfsTripsByRouteId(gtfsRouteId)
        : null;
    List<String>? tripIds =
    trips?.map((t) => t.id).toList(); // Converts trips to tripIds

    // 3. Collect positions of vehicles
    if (tripIds != null) {
      for (var entity in feedMessage.entity) {
        if (tripIds.contains(entity.vehicle.trip.tripId)) {
          double latitude = entity.vehicle.position.latitude;
          double longitude = entity.vehicle.position.longitude;
          LatLng newLocation = LatLng(latitude, longitude);
          locations.add(newLocation);
        }
      }
    }

    return locations;
  }

  Future<void> getTramTripUpdates() async {
    final feedMessage = await gtfsApi.tramTripUpdates();

    for (var entity in feedMessage.entity) {
      print(entity);
    }
  }
}