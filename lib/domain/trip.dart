import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_project/ptv_service.dart';

import 'package:flutter_project/database/helpers/departure_helpers.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:get/get.dart';

part 'trip.g.dart';

@JsonSerializable()
class Trip {
  String? uniqueID; // unique ID for the widget timeline
  Stop? stop;
  Route? route;
  Direction? direction;
  int? index;
  // todo: add GeoPath as an attribute

  // Constructor
  Trip();    // Empty Transport    // todo: delete this

  Trip.withStopRoute(Stop stop, Route route, Direction direction) {
    this.stop = stop;
    this.route = route;
    this.direction = direction;
  }

  Trip.withAttributes(Stop? stop, Route? route, Direction? direction) {
    // this.location = location;
    this.stop = stop;
    this.route = route;
    this.direction = direction;

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

    // Early exit if any of the prerequisites are null
    // if (routeType == null || stopId == null || directionId == null || routeId == null) {
    if (routeType == null || stopId == null || routeId == null) {
      print("( trip.dart -> updatedDepartures() ) -- Early Exit for routeType, stopId, directionId, routeId = $routeType, $stopId, $directionId, $routeId");
      return;
    }

    // Gets Departures and saves to instance
    PtvService ptvService = PtvService();
    departureCount = departureCount ?? defaultDepartureCount;
    departures = await ptvService.fetchDepartures(
        routeType, stopId, routeId, directionId: directionId, maxResults: departureCount.toString());

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

        await Get.find<db.AppDatabase>().addDeparture(scheduledUTC, estimatedUTC, runRef, stopId, routeId, directionId, hasLowFloor, hasAirConditioning);
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

  // DELETE LATER ITS BEING USED IN OLD SCREENS
  Future<List<Trip>> splitByDirection() async {

    // Get the two directions a route can go, and set each new transport to one of them
    List<Direction> directions = await fetchRouteDirections();
    Trip newTransport1 = Trip.withAttributes(stop, route, directions[0]);
    Trip newTransport2 = Trip.withAttributes(stop, route, directions[1]);

    List<Trip> newTransportList = [newTransport1, newTransport2];

    // print("( trip.dart -> getRouteDirections() ) -- newTransportList: \n$newTransportList");
    return newTransportList;
  }

  // todo: use the ptv service version of this
  Future<List<Direction>> fetchRouteDirections() async {
    String? routeId = route?.id.toString();
    List<Direction> directions = [];

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().directions(routeId!);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("( trip.dart -> fetchRouteDirections ) -- Null Data response Improper Location Data");
      return [];
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      int id = direction["direction_id"];
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      Direction newDirection =
      Direction(id: id, name: name, description: description);

      directions.add(newDirection);
    }

    // print("( trip.dart -> fetchRouteDirections ) -- Directions: $directions");
    return directions;
  }

  void setIndex(int index) {
    this.index = index;
  }

  // Make the toString for list representation???~
  @override
  String toString() {
    String str = "";

    if (stop != null) {str += stop.toString();}
    if (route != null) {str += route.toString();}
    if (direction != null) {str += direction.toString();}
    if (departures != null) {str += departures.toString();}

    return str;
  }

  // todo: factory constructor fromDB

  // Methods for JSON Serialization
  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
  Map<String, dynamic> toJson() => _$TripToJson(this);
}