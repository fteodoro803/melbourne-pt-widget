import 'package:flutter_project/ptvInfoClasses/LocationInfo.dart';
import 'package:flutter_project/ptvInfoClasses/RouteTypeInfo.dart';

class Selections {      // consider changing these to the Info classes
  // Public Transport Type
  RouteType? routeType;

  // location
  Location? location;

  // stop
  String? stopId;
  String? stopName;
  String? stopSuburb;
  String? stopLatitude;
  String? stopLongitude;

  @override
  String toString() {
    String str = "";

    if (routeType != null) {str += routeType.toString();}
    if (location != null) {str += location.toString();}

    return str;
  }
}