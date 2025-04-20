import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_project/domain/route.dart' as pt_route;

class DepartureStatus {
  final String status;
  final int? timeDifference;

  DepartureStatus(this.status, this.timeDifference);
}

class TransportUtils {
  // Function to compare estimated and scheduled departure times for a transport departure
  static DepartureStatus getDepartureStatus(String? estimatedDepartureTime, String? scheduledDepartureTime) {
    if (estimatedDepartureTime == null || scheduledDepartureTime == null) {
      return DepartureStatus("Scheduled", null); // Default to On-time if either value is null
    }

    try {
      int? timeDifference = TimeUtils.timeDifference(scheduledDepartureTime, estimatedDepartureTime)?['minutes'];

      // Compare the times
      if (timeDifference != null && timeDifference > 0) {
        return DepartureStatus("Delayed", timeDifference.abs()); // Estimated departure is later than scheduled, so it's late
      } else if (timeDifference != null && timeDifference < 0) {
        return DepartureStatus("Early", timeDifference.abs()); // Estimated departure is earlier than scheduled, so it's early
      } else if (timeDifference != null && timeDifference == 0){
        return DepartureStatus("On time", null); // Both times are the same, so it's on-time
      } else {
        return DepartureStatus("Scheduled", null);
      }
    } catch (e) {
      return DepartureStatus("Scheduled", null); // Default to "Scheduled" if there is any error in parsing the time
    }
  }

  static getLabel(pt_route.Route route, String routeType) {
    String routeLabel;
    if (routeType == "train") {
      routeLabel = route.name;
    }
    else if (routeType == "vLine") {
      routeLabel = "V/Line";
    }
    else {
      routeLabel = route.number;
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
}

class TimeUtils {
  // Finds time difference in days and minutes between system time and given departure time
  static Map<String, int>? timeDifference(String inputTime1, [String? inputTime2]) {
    try {
      // Convert both input times to uppercase to handle lowercase am/pm
      inputTime1 = inputTime1.toUpperCase();
      inputTime2 = inputTime2?.toUpperCase();

      // Set the input time format
      var formatter = DateFormat('hh:mma');

      // Parse the first input time string into a DateTime object
      DateTime inputDate1 = formatter.parse(inputTime1);
      DateTime fullInputDate1 = DateTime.now().copyWith(
          hour: inputDate1.hour,
          minute: inputDate1.minute,
          second: 0,
          millisecond: 0
      );

      // If a second input time is provided, compute the difference between them
      if (inputTime2 != null) {
        DateTime inputDate2 = formatter.parse(inputTime2);
        DateTime fullInputDate2 = DateTime.now().copyWith(
            hour: inputDate2.hour,
            minute: inputDate2.minute,
            second: 0,
            millisecond: 0
        );

        // Find the difference between the two input times
        Duration difference = fullInputDate1.difference(fullInputDate2); // Reverse the order to reflect the desired sign

        bool isNegative = difference.isNegative;

        // Get the absolute values first
        int totalMinutes = difference.inMinutes.abs();
        int days = totalMinutes ~/ (24 * 60);
        int hours = (totalMinutes % (24 * 60)) ~/ 60;
        int minutes = totalMinutes % 60;

        // Apply the sign if needed
        if (isNegative) {
          days = -days;
          hours = -hours;
          minutes = -minutes;
        }

        // Return the difference with sign
        return {'days': days, 'hours': hours, 'minutes': minutes};
      } else {
        // If only one time is provided, calculate the difference between input time and current system time
        DateTime currentDate = DateTime.now();

        // Find the difference between the current time and the input time
        Duration difference = fullInputDate1.difference(currentDate); // Positive if future, negative if past

        // Determine if the overall difference is negative
        bool isNegative = difference.isNegative;

        // Get the absolute values first
        int totalMinutes = difference.inMinutes.abs();
        int days = totalMinutes ~/ (24 * 60);
        int hours = (totalMinutes % (24 * 60)) ~/ 60;
        int minutes = totalMinutes % 60;

        // Apply the sign if needed
        if (isNegative) {
          days = -days;
          hours = -hours;
          minutes = -minutes;
        }

        // Return the difference with sign
        return {'days': days, 'hours': hours, 'minutes': minutes};
      }
    } catch (e) {
      return null; // If the input format is incorrect or other errors
    }
  }

  static String? minutesToString(Map<String, int>? timeMap) {
    if (timeMap?['days'] == 0 && timeMap?['hours'] == 0 && timeMap!['minutes']! >= 0) {
      if (timeMap['minutes'] == 0) {
        return "Now";
      }
      else {
        String minutes = timeMap['minutes'].toString();
        return "$minutes min";
      }
    } else {
      return null;
    }
  }

  static String trimTime(String timeString) {
    String timeElement;
    String timeOfDay;
    if (timeString[0] == "0") {
      timeElement = timeString.substring(1, timeString.length - 2);
      timeOfDay = timeString.substring(timeString.length - 2, timeString.length);

      return "$timeElement$timeOfDay";
    }
    else {
      return timeString;
    }
  }
}

class ColourUtils {
  // Function to convert hex string to Color
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

  // Function to return color based on departure status
  static Color getColorForStatus(String status) {
    switch (status) {
      case "Delayed":
        return Color(0xFFC57070); // Red for late
      case "Early":
        return Color(0xFFC5B972); // Yellow for early
      case "On time":
        return Color(0xFF8ECF93); // Yellow for early
      case "Scheduled":
      default:
        return Color(0xFFB8B8B8); // Green for on-time or default
    }
  }
}