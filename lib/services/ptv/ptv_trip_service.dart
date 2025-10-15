import 'package:flutter_project/database/helpers/direction_helpers.dart';
import 'package:flutter_project/database/helpers/route_helpers.dart';
import 'package:flutter_project/database/helpers/stop_helpers.dart';
import 'package:flutter_project/database/helpers/trip_helpers.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/services/ptv/ptv_base_service.dart';

class PtvTripService extends PtvBaseService {
  Future<void> saveTrip(Trip trip) async {
    String? uniqueId = trip.uniqueID;
    int? routeTypeId = trip.route?.type.id;
    int? routeId = trip.route?.id;
    int? stopId = trip.stop?.id;
    int? directionId = trip.direction?.id;
    int? index = trip.index;

    if (uniqueId != null &&
        routeTypeId != null &&
        routeId != null &&
        stopId != null &&
        directionId != null) {
      await database.addTrip(
          uniqueId: uniqueId,
          routeTypeId: routeTypeId,
          routeId: routeId,
          stopId: stopId,
          directionId: directionId,
          index: index);
    } else {
      print(
          " ( ptv_service.dart -> saveTrip ) -- one of the following is null: uniqueId, routeTypeId, routeId, stopId, directionId");
    }
  }

  /// Checks if Trip is in Database
  Future<bool> isTripSaved(Trip trip) async {
    if (trip.uniqueID != null) {
      return await database.isTripInDatabase(trip.uniqueID!);
    } else {
      return false;
    }
  }

  /// Get Trip from database
  Future<List<Trip>> loadTrips() async {
    List<Trip> tripList = [];

    var dbTrips = await database.getTrips();
    Route? route;
    Stop? stop;
    Direction? direction;
    int? index;

    // Convert database trip to domain trip
    for (var dbTrip in dbTrips) {
      var dbRoute = await database.getRouteById(dbTrip.routeId);
      route = dbRoute != null ? await Route.fromDbAsync(dbRoute) : null;

      var dbStop = await database.getStopById(dbTrip.stopId);
      stop = dbStop != null ? Stop.fromDb(dbStop: dbStop) : null;
      // todo: get sequence to stop

      var dbDirection = await database.getDirectionById(dbTrip.directionId);
      direction = dbDirection != null ? Direction.fromDb(dbDirection) : null;

      index = dbTrip.index ?? 999;

      Trip newTrip = Trip(stop: stop, route: route, direction: direction);
      newTrip.setIndex(index);
      tripList.add(newTrip);
    }

    return tripList;
  }

  /// Remove Trip from database
  Future<void> deleteTrip(String tripId) async {
    await database.removeTransport(tripId);
  }
}
