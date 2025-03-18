import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_info_classes/location_info.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:json_annotation/json_annotation.dart';

import 'departure_service.dart';

part 'transport.g.dart';

@JsonSerializable()
class Transport {
  String? uniqueID; // unique ID for the widget timeline
  RouteType? routeType;
  Location? location;
  Stop? stop;
  Route? route;
  RouteDirection? direction;
  String? uniqueID; // unique ID for the widget timeline

  // Constructor
  Transport();

  // Next 3 Departures, make a function to update this on selected intervals later
  List<Departure>? departures;

  // Update Departures
  Future<void> updateDepartures() async {
    String? routeType = this.routeType?.type;
    String? stopId = stop?.id;
    String? directionId = direction?.id;
    String? routeId = route?.id;

    // Early exit if any of the prerequisites are null
    if (routeType == null || stopId == null || directionId == null || routeId == null) {
      // if (kDebugMode) {
      //   print("( transport.dart -> updatedDepartures() ) -- Early Exit for routeType, stopId, directionId, routeId = $routeType, $stopId, $directionId, $routeId");
      // }
      return;
    }

    // Gets Departures and saves to instance
    DepartureService departureService = DepartureService();
    departures = await departureService.fetchDepartures(
        routeType, stopId, directionId, routeId);
    // if (kDebugMode) {
    //   print("( transport.dart -> updatedDepartures() ) -- Updated Departures: \n $departures");
    // }

    generateUniqueID();
  }

  void generateUniqueID() {
    if (routeType != null && stop != null && route != null && direction != null) {
      uniqueID = "${routeType?.type}-${stop?.id}-${route?.id}-${direction?.id}";
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

  // Methods for JSON Serialization
  factory Transport.fromJson(Map<String, dynamic> json) => _$TransportFromJson(json);
  Map<String, dynamic> toJson() => _$TransportToJson(this);
}