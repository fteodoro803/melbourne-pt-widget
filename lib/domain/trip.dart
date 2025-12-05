import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/stop.dart';

import 'package:flutter_project/services/ptv_service.dart';

import 'package:flutter_project/database/database.dart' as db;
import 'package:get/get.dart';

class Trip {
  Stop? stop;
  Route? route;
  Direction? direction;

  String? uniqueID; // unique ID for the widget timeline
  int? index;
  // todo: add GeoPath as an attribute

  // Constructor
  Trip({this.stop, this.route, this.direction}) {
    generateUniqueID();
  }

  // isEqualTo method to compare all properties
  bool isEqualTo(Trip other) {
    return uniqueID == other.uniqueID;
  }

  // Next 3 Departures
  List<Departure>? departures;

  // Update Departures
  Future<void> updateDepartures({int? departureCount}) async {
    int defaultDepartureCount = 20;
    String? routeType = route?.type.id.toString();
    String? stopId = stop?.id.toString();
    String? directionId = direction?.id.toString();
    String? routeId = route?.id.toString();
    db.Database database = Get.find<db.Database>();

    // Early exit if any of the prerequisites are null
    if (routeType == null || stopId == null || routeId == null) {
      print(
          "( trip.dart -> updatedDepartures() ) -- Early Exit for routeType, stopId, directionId, routeId = $routeType, $stopId, $directionId, $routeId");
      return;
    }

    // Gets Departures and saves to instance
    PtvService ptvService = Get.find<PtvService>();
    departureCount = departureCount ?? defaultDepartureCount;
    departures = await ptvService.departures.fetchDepartures(
        routeType: routeType,
        stopId: stopId,
        routeId: routeId,
        directionId: directionId,
        maxResults: departureCount.toString());

    // Saves Departures to Database
    if (departures != null && departures!.isNotEmpty) {
      for (var departure in departures!) {
        DateTime? scheduledUTC = departure.scheduledDepartureUTC;
        DateTime? estimatedUTC = departure.estimatedDepartureUTC;
        String? runRef = departure.runRef;
        int? stopId = departure.stopId;
        int? routeId = route?.id;
        int? directionId = direction?.id;
        bool? hasLowFloor = departure.hasLowFloor;
        bool? hasAirConditioning = departure.hasAirConditioning;

        // Can only add to database with valid ids
        if (stopId != null && routeId != null &&
            directionId != null && runRef != null) {
          var dbDeparture = database.departuresDao.createDepartureCompanion(
              runRef: runRef,
              stopId: stopId,
              routeId: routeId,
              directionId: directionId,
              scheduledDepartureUTC: scheduledUTC,
              estimatedDepartureUTC: estimatedUTC,
              hasAirConditioning: hasAirConditioning,
              hasLowFloor: hasLowFloor
          );

          await database.departuresDao.addDeparture(dbDeparture);
        }
      }
    }

    // print("( trip.dart -> updatedDepartures() ) -- Updated Departures: \n $departures");

    generateUniqueID();
  }

  // todo: this should probably be made in the constructor, rather than in the updating departures
  void generateUniqueID() {
    if (stop != null && route != null && direction != null) {
      uniqueID = "${stop?.id}-${route?.id}-${direction?.id}";
    }
  }

  void setIndex(int index) {
    this.index = index;
  }

  // Make the toString for list representation???~
  @override
  String toString() {
    String str = "";

    if (stop != null) {
      str += stop.toString();
    }
    if (route != null) {
      str += route.toString();
    }
    if (direction != null) {
      str += direction.toString();
    }
    if (departures != null) {
      str += departures.toString();
    }

    return str;
  }

  // todo: factory constructor fromDB
}
