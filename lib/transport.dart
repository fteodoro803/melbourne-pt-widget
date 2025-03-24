import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/ptv_api_service.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_info_classes/location_info.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ptv_service.dart';

part 'transport.g.dart';

@JsonSerializable()
class Transport {
  String? uniqueID; // unique ID for the widget timeline
  RouteType? routeType;
  Location? location;
  Stop? stop;
  Route? route;
  RouteDirection? direction;

  // Constructor
  Transport();    // Empty Transport
  Transport.withAttributes(RouteType? routeType, Location? location, Stop? stop, Route? route, RouteDirection? direction) {
    this.routeType = routeType;
    this.location = location;
    this.stop = stop;
    this.route = route;
    this.direction = direction;
  }

  // Next 3 Departures, make a function to update this on selected intervals later
  List<Departure>? departures;

  // Update Departures
  Future<void> updateDepartures() async {
    String? routeType = this.routeType?.type;
    String? stopId = stop?.id;
    String? directionId = direction?.id;
    String? routeId = route?.id;

    // print("( transport.dart -> updateDepartures() ) -- transport file: \n${toString()} ");

    // Early exit if any of the prerequisites are null
    // if (routeType == null || stopId == null || directionId == null || routeId == null) {
    if (routeType == null || stopId == null || routeId == null) {
      print("( transport.dart -> updatedDepartures() ) -- Early Exit for routeType, stopId, directionId, routeId = $routeType, $stopId, $directionId, $routeId");
      return;
    }

    // Gets Departures and saves to instance
    PtvService ptvService = PtvService();
    departures = await ptvService.fetchDepartures(
        routeType, stopId, routeId, directionId: directionId);

    // print("( transport.dart -> updatedDepartures() ) -- Updated Departures: \n $departures");

    generateUniqueID();
  }

  void generateUniqueID() {
    if (routeType != null && stop != null && route != null && direction != null) {
      uniqueID = "${routeType?.type}-${stop?.id}-${route?.id}-${direction?.id}";
    }
  }

  Future<List<Transport>> splitByDirection() async {

    // Get the two directions a route can go, and set each new transport to one of them
    List<RouteDirection> directions = await fetchRouteDirections();
    Transport newTransport1 = Transport.withAttributes(routeType, location, stop, route, directions[0]);
    Transport newTransport2 = Transport.withAttributes(routeType, location, stop, route, directions[1]);

    List<Transport> newTransportList = [newTransport1, newTransport2];

    // print("( transport.dart -> getRouteDirections() ) -- newTransportList: \n$newTransportList");
    return newTransportList;
  }

  Future<List<RouteDirection>> fetchRouteDirections() async {
    String? routeId = route?.id;
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
      String id = direction["direction_id"].toString();
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      RouteDirection newDirection =
      RouteDirection(id: id, name: name, description: description);

      directions.add(newDirection);
    }

    // print("( transport.dart -> fetchRouteDirections ) -- Directions: $directions");
    return directions;
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

  // Methods for JSON Serialization
  factory Transport.fromJson(Map<String, dynamic> json) => _$TransportFromJson(json);
  Map<String, dynamic> toJson() => _$TransportToJson(this);
}