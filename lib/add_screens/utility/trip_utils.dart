import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_project/add_screens/utility/time_utils.dart';

import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/domain/route.dart' as pt_route;

class TripUtils {

  static String? getLabel(pt_route.Route? route, String? routeType) {
    if (route == null || routeType == null) {
      return null;
    }

    String routeLabel;
    if (routeType == "train") {
      routeLabel = route.name;
    }
    else if (routeType == "vLine") {
      routeLabel = "V/Line";
    }
    else {
      routeLabel = route.number;
      String tempRouteLabel = routeLabel.toLowerCase();
      if (tempRouteLabel.contains("combined")) {
        routeLabel = routeLabel.toLowerCase();
        routeLabel = routeLabel.replaceAll(" combined", "");
      }
      if (routeLabel == "") {
        List<String> nameComponents = route.name.split(' ');
        routeLabel = nameComponents[0];
      }
    }
    return routeLabel;
  }

  static getName(pt_route.Route route, String routeType) {
    String? routeName;
    if (routeType == "train") {
      routeName = null;
    }
    else {
      routeName = route.name;
    }
    return routeName;
  }

  static getStatusColor(Departure departure) {
    DepartureStatus status = TimeUtils.getDepartureStatus(departure.scheduledDepartureUTC, departure.estimatedDepartureUTC);
    return status.getColorString;
  }

  static getTimeString(Departure departure) {
    DepartureStatus status = TimeUtils.getDepartureStatus(
        departure.estimatedDepartureUTC, departure.scheduledDepartureUTC);
    if (status.isWithinAnHour && status.hasDeparted == false) {
      return TimeUtils.minutesString(
          departure.estimatedDepartureUTC,
          departure.scheduledDepartureUTC!);
    }
  }
}

class ColourUtils {
  /// Function to convert hex string to Color
  static Color hexToColour(String hexColour) {
    // Remove the '#' if it's there, just in case
    hexColour = hexColour.replaceAll('#', '');

    // Add the alpha value to the hex code if it's missing
    if (hexColour.length == 6) {
      hexColour = 'FF' + hexColour; // Default alpha value (FF for full opacity)
    }

    // Convert hex string to integer and create Color object
    return Color(int.parse('0x$hexColour'));
  }
}
