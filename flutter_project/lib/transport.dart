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
  RouteType? routeType;
  Location? location;
  Stop? stop;
  Route? route;
  RouteDirection? direction;

  // Constructor
  Transport();

  // Next 3 Departures, make a function to update this on selected intervals later
  List<Departure>? departures;

  // Update Departures
  Future<void> updateDepartures() async {
    String? routeType = this.routeType?.type;
    String? stopId = this.stop?.id;
    String? directionId = this.direction?.id;
    String? routeId = this.route?.id;

    // Early exit if any of the prerequisites are null
    if (routeType == null || stopId == null || directionId == null || routeId == null) {
      return;
    }

    // Gets Departures and saves to instance
    DepartureService departureService = DepartureService();
    this.departures = await departureService.fetchDepartures(
        routeType, stopId, directionId, routeId);
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