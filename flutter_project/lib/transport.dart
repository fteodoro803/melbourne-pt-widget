import 'package:flutter_project/ptvInfoClasses/LocationInfo.dart';
import 'package:flutter_project/ptvInfoClasses/RouteDirectionInfo.dart';
import 'package:flutter_project/ptvInfoClasses/RouteInfo.dart';
import 'package:flutter_project/ptvInfoClasses/RouteTypeInfo.dart';
import 'package:flutter_project/ptvInfoClasses/StopInfo.dart';

class Transport {
  RouteType? routeType;
  Location? location;
  Stop? stop;
  Route? route;
  RouteDirection? direction;

  @override
  String toString() {
    String str = "";

    if (routeType != null) {str += routeType.toString();}
    if (location != null) {str += location.toString();}
    if (stop != null) {str += stop.toString();}
    if (route != null) {str += route.toString();}
    if (direction != null) {str += direction.toString();}

    return str;
  }
}