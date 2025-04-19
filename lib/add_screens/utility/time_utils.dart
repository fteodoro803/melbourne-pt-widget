import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;

class DepartureStatus {
  final String status;
  final int? timeDifference;
  final bool? hasDeparted;
  final bool isWithinAnHour;

  DepartureStatus(this.status, this.timeDifference, this.hasDeparted, this.isWithinAnHour);
}

class TransportUtils {
  // Function to compare estimated and scheduled departure times for a transport departure
  static DepartureStatus getDepartureStatus(DateTime? estimated, DateTime? scheduled) {
    if (estimated == null || scheduled == null) {
      return DepartureStatus("Scheduled", null, false, false); // Default to On-time if either value is null
    }

    Map<String, int>? timeMap = TimeUtils.timeDifference(estimated);
    Map<String, int>? statusTimeMap = TimeUtils.timeDifference(scheduled, estimated);

    if (timeMap == null || statusTimeMap == null) {
      return DepartureStatus("Scheduled", null, false, false);
    }

    bool hasDeparted = TimeUtils.hasDeparted(timeMap);
    bool isWithinAnHour = timeMap['hours']! == 0 && timeMap['days']! == 0;

    try {
      int? minutes = statusTimeMap['minutes'];

      // Compare the times
      if (minutes != null && minutes > 0) {
        return DepartureStatus("Late", minutes.abs(), hasDeparted, isWithinAnHour); // Estimated departure is later than scheduled, so it's late
      } else if (minutes != null && minutes < 0) {
        return DepartureStatus("Early", minutes.abs(), hasDeparted, isWithinAnHour); // Estimated departure is earlier than scheduled, so it's early
      } else if (minutes != null && minutes == 0){
        return DepartureStatus("On time", null, hasDeparted, isWithinAnHour); // Both times are the same, so it's on-time
      } else {
        return DepartureStatus("Scheduled", null, hasDeparted, isWithinAnHour);
      }
    } catch (e) {
      return DepartureStatus("Scheduled", null, false, false); // Default to "Scheduled" if there is any error in parsing the time
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
  /// Calculates time difference between two ISO 8601 UTC formatted times or between
  /// one ISO 8601 UTC time and the current system time.
  ///
  /// Example input: "2025-04-19T01:47:00.000Z"
  ///
  /// Returns a map containing the difference in days, hours, and minutes,
  /// or null if there's an error parsing the input.
  static Map<String, int>? timeDifference(DateTime inputDate1, [DateTime? inputDate2]) {
    try {
      // Determine the reference time (either second ISO time or current time)
      DateTime referenceTime;

      if (inputDate2 != null) {
        // Use the second provided ISO time
        referenceTime = inputDate2;
      } else {
        // Use current system time in UTC
        referenceTime = DateTime.now().toUtc();
      }

      // Calculate the difference (positive if inputDate1 is in the future compared to reference)
      Duration difference = inputDate1.difference(referenceTime);

      // Extract the difference components with proper sign
      bool isNegative = difference.isNegative;
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
    } catch (e) {
      return null; // If the input format is incorrect or other errors
    }
  }

  /// Converts an ISO 8601 UTC timestamp to a readable format in Melbourne timezone
  ///
  /// Input format example: "2025-04-19T01:47:00.000Z"
  ///
  /// Returns a map with year, month, day, hour (12-hour format), minute, and period (AM/PM)
  static Map<String, dynamic> convertIsoToReadable(DateTime utcTime) {
    try {

      final melbourne = tz.getLocation('Australia/Melbourne');
      final melbourneTime = tz.TZDateTime.from(utcTime, melbourne);

      // Determine if it's AM or PM
      String period = (melbourneTime.hour < 12) ? 'am' : 'pm';

      // Convert to 12-hour format
      int hour12 = melbourneTime.hour % 12;
      if (hour12 == 0) hour12 = 12; // Convert 0 to 12 for 12 AM/PM

      // Month names
      List<String> monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      // Create the readable format object
      return {
        'year': melbourneTime.year,
        'month': monthNames[melbourneTime.month - 1],
        'monthNum': melbourneTime.month,
        'day': melbourneTime.day,
        'hour': hour12,
        'minute': melbourneTime.minute,
        'period': period,
        'weekday': _getWeekdayName(melbourneTime.weekday),
        'formatted': '${hour12.toString().padLeft(2, '0')}:${melbourneTime.minute.toString().padLeft(2, '0')} $period'
      };
    } catch (e) {
      return {
        'error': 'Invalid timestamp format',
        'details': e.toString()
      };
    }
  }

  /// Helper function to get the weekday name
  static String _getWeekdayName(int weekday) {
    List<String> weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu',
      'Fri', 'Sat', 'Sun'
    ];
    return weekdays[weekday - 1];
  }

  // Departed late • 4:45 pm          1 min ago
  // Departed on time • 4:45 pm       1 min ago
  // Departed early • 4:22 pm         1 min ago

  // 4 min late • /4:45 pm            1 min
  // On time • 4:45 pm                1 min
  // 4 min early • /4:45 pm
  // Scheduled • 4:45 pm              1 min

  // 4 min ago
  // 4 min ago
  // 6 min ago
  static String statusString(DepartureStatus status) {
    if (status.hasDeparted!) {
      if (status.status == "Scheduled") {
        return "Departed";
      } else {
        return "Departed ${status.status.toLowerCase()}";
      }
    } else {
      if (status.status == "Late" || status.status == "Early") {
        return "${status.timeDifference} min ${status.status.toLowerCase()}";
      } else {
        return status.status;
      }
    }
  }

  static bool showDepartureTime(DateTime isoTime) {
    Map<String, int>? timeDifference = TimeUtils.timeDifference(isoTime);
    print(timeDifference);
    if (timeDifference != null
        && (timeDifference['hours']!.abs() == 0
        || timeDifference['days']! > 0)) {
      return true;
    } else {
      return false;
    }
  }

  /// Helper function to determine whether transport has departed
  static bool hasDeparted(Map<String, int>? timeMap) {
    if (timeMap!['days']! < 0 || timeMap['hours']! < 0 || timeMap['minutes']! < 0) {
      return true;
    }
    return false;
  }

  /// Converts ISO 8601 UTC timestamp into a string depicting time until or since a departure
  ///
  /// If departure is within an hour from current time, returns minutes string
  /// Otherwise, return the time or date of departure in a simplified format
  static String minutesString(DateTime? isoTimeEstimated, DateTime isoTimeScheduled) {
    DateTime isoTime = isoTimeEstimated ?? isoTimeScheduled;
    Map<String, int>? timeMap = timeDifference(isoTime);

    if (timeMap == null) {
      return "";
    }

    bool hasDeparted = TimeUtils.hasDeparted(timeMap);

    if (timeMap['days']! == 0 && timeMap['hours']! == 0 && timeMap['minutes']!.abs() >= 0) {
      if (timeMap['minutes'] == 0) {
        return "Now";
      }
      else {
        String minutes = timeMap['minutes']!.abs().toString();
        if (hasDeparted) {
          return "$minutes min ago";
        } else {
          return "$minutes min";
        }
      }
    } else {
      return shouldShowMonth(isoTime, timeMap['days']);
    }
  }

  static String shouldShowMonth(DateTime isoTime, [int? days]) {
    final differenceInDays = days?.abs() ?? TimeUtils.timeDifference(isoTime)!['days']!.abs();
    if (differenceInDays > 0) {
      return trimTime(isoTime, true);
    } else {
      return trimTime(isoTime, false);
    }
  }

  /// Helper function to convert ISO time into a string
  static String trimTime(DateTime isoTime, bool showMonth) {
    final isoReadableTime = convertIsoToReadable(isoTime);
    if (showMonth) {
      String weekday = isoReadableTime['weekday'].toString();
      String day = isoReadableTime['day'].toString();
      String month = isoReadableTime['month'].toString();
      return "$weekday, $day $month";
    } else {
      String hour = isoReadableTime['hour'].toString();
      String minute = isoReadableTime['minute'].toString();
      String period = isoReadableTime['period'].toString();
      if (minute.length == 1) {
        minute = "0$minute";
      }
      return "$hour:$minute $period";
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

  /// Function to return color based on departure status
  static Color getColorForStatus(String status) {
    switch (status) {
      case "Late":
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