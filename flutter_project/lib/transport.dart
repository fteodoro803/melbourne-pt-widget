import 'package:flutter_project/ptvInfoClasses/departure_info.dart';
import 'package:flutter_project/ptvInfoClasses/location_info.dart';
import 'package:flutter_project/ptvInfoClasses/route_direction_info.dart';
import 'package:flutter_project/ptvInfoClasses/route_info.dart';
import 'package:flutter_project/ptvInfoClasses/route_type_info.dart';
import 'package:flutter_project/ptvInfoClasses/stop_info.dart';

class Transport {
  RouteType? routeType;
  Location? location;
  Stop? stop;
  Route? route;
  RouteDirection? direction;

  // Next 3 Departures, make a function to update this on selected intervals later
  List<Departure>? departures;

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
}