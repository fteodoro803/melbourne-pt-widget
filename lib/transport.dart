import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_info_classes/location_info.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ptv_service.dart';

import 'database/helpers/departureHelpers.dart';
import 'database/database.dart' as db;
import 'package:get/get.dart';

part 'transport.g.dart';

@JsonSerializable()
class Transport {
  String? uniqueID; // unique ID for the widget timeline
  RouteType? routeType;
  Location? location;
  Stop? stop;
  Route? route;
  RouteDirection? direction;
  // todo: add GeoPath as an attribute

  // Constructor
  Transport();    // Empty Transport    // todo: delete this

  Transport.withStopRoute(Stop stop, Route route, RouteDirection direction) {
    this.stop = stop;
    this.route = route;
    this.direction = direction;
  }

  Transport.withAttributes(RouteType? routeType, Stop? stop, Route? route, RouteDirection? direction) {
    this.routeType = routeType;
    // this.location = location;
    this.stop = stop;
    this.route = route;
    this.direction = direction;

    generateUniqueID();
  }

  // isEqualTo method to compare all properties
  bool isEqualTo(Transport other) {
    return uniqueID == other.uniqueID;
  }

  // Next 3 Departures
  List<Departure>? departures;

  // Update Departures
  Future<void> updateDepartures() async {
    String? routeType = this.routeType?.id.toString();
    String? stopId = stop?.id.toString();
    String? directionId = direction?.id.toString();
    String? routeId = route?.id.toString();

    // Early exit if any of the prerequisites are null
    // if (routeType == null || stopId == null || directionId == null || routeId == null) {
    if (routeType == null || stopId == null || routeId == null) {
      print("( transport.dart -> updatedDepartures() ) -- Early Exit for routeType, stopId, directionId, routeId = $routeType, $stopId, $directionId, $routeId");
      return;
    }

    // Gets Departures and saves to instance
    PtvService ptvService = PtvService();
    int departureCount = 3;
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

    // print("( transport.dart -> updatedDepartures() ) -- Updated Departures: \n $departures");

    generateUniqueID();
  }

  // todo: this should probably be made in the constructor, rather than in the updating departures
  void generateUniqueID() {
    if (routeType != null && stop != null && route != null && direction != null) {
      uniqueID = "${routeType?.id}-${stop?.id}-${route?.id}-${direction?.id}";
    }
  }

  // DELETE LATER ITS BEING USED IN OLD SCREENS
  Future<List<Transport>> splitByDirection() async {

    // Get the two directions a route can go, and set each new transport to one of them
    List<RouteDirection> directions = await fetchRouteDirections();
    Transport newTransport1 = Transport.withAttributes(routeType, stop, route, directions[0]);
    Transport newTransport2 = Transport.withAttributes(routeType, stop, route, directions[1]);

    List<Transport> newTransportList = [newTransport1, newTransport2];

    // print("( transport.dart -> getRouteDirections() ) -- newTransportList: \n$newTransportList");
    return newTransportList;
  }

  // todo: use the ptv service version of this
  Future<List<RouteDirection>> fetchRouteDirections() async {
    String? routeId = route?.id.toString();
    List<RouteDirection> directions = [];

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeDirections(routeId!);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("( transport.dart -> fetchRouteDirections ) -- Null Data response Improper Location Data");
      return [];
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      int id = direction["direction_id"];
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      RouteDirection newDirection =
      RouteDirection(id: id, name: name, description: description);

      directions.add(newDirection);
    }

    // print("( transport.dart -> fetchRouteDirections ) -- Directions: $directions");
    return directions;
  }

  void setRouteType(int id) {
    try {
      routeType = RouteType.fromId(id);     // todo: remove the try/catch, it might already be covered in the creation of the enum? Or maybe keep it bc it helps with crashes
    } catch (e) {
      print(e); // Logs unknown route type errors
    }
  }

  // Make the toString for list representation???~
  @override
  String toString() {
    String str = "";

    if (routeType != null) {str += routeType.toString();}
    if (location != null) {str += location.toString();}
    if (stop != null) {str += stop.toString();}
    if (route != null) {str += route.toString();}
    if (direction != null) {str += direction.toString();}
    if (departures != null) {str += departures.toString();}

    return str;
  }

  // todo: factory constructor fromDB

  // Methods for JSON Serialization
  factory Transport.fromJson(Map<String, dynamic> json) => _$TransportFromJson(json);
  Map<String, dynamic> toJson() => _$TransportToJson(this);
}