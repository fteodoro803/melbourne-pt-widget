import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    // Convert the time strings to DateTime objects for comparison
    var formatter = DateFormat('hh:mma'); // Adjust the format according to your input time format

    try {
      DateTime estimatedTime = formatter.parse(estimatedDepartureTime.toUpperCase());
      DateTime scheduledTime = formatter.parse(scheduledDepartureTime.toUpperCase());

      // Compare the times
      if (estimatedTime.isAfter(scheduledTime)) {
        int? timeDelayed = TimeUtils.timeDifference(scheduledDepartureTime, estimatedDepartureTime)?['minutes'];
        return DepartureStatus("Delayed", timeDelayed); // Estimated departure is later than scheduled, so it's late
      } else if (estimatedTime.isBefore(scheduledTime)) {
        int? timeEarly = TimeUtils.timeDifference(estimatedDepartureTime, scheduledDepartureTime)?['minutes'];
        return DepartureStatus("Early", timeEarly); // Estimated departure is earlier than scheduled, so it's early
      } else {
        return DepartureStatus("On time", null); // Both times are the same, so it's on-time
      }
    } catch (e) {
      return DepartureStatus("Scheduled", null); // Default to "On-time" if there is any error in parsing the time
    }
  }

  // Function to return color based on departure status
  static Color getColorForStatus(String status) {
    switch (status) {
      case "Delayed":
        return Color(0xFFCA6868); // Red for late
      case "Early":
        return Color(0xFFC5B972); // Yellow for early
      case "On time":
        return Color(0xFF71CA63); // Yellow for early
      case "Scheduled":
      default:
        return Colors.white; // Green for on-time or default
    }
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
        Duration difference = fullInputDate2.difference(fullInputDate1);

        int days = difference.inDays;
        int hours = difference.inHours % 24;
        int minutes = difference.inMinutes % 60;

        return {'days': days, 'hours': hours, 'minutes': minutes};
      } else {
        // If only one time is provided, calculate the difference between input time and current system time
        DateTime currentDate = DateTime.now();

        // Find the difference between current time and the input time
        Duration difference = fullInputDate1.difference(currentDate);

        // Get the days and minutes from the difference
        int days = difference.inDays;
        int hours = difference.inHours % 24;
        int minutes = difference.inMinutes % 60;

        return {'days': days, 'hours': hours, 'minutes': minutes};
      }
    } catch (e) {
      return null; // If the input format is incorrect or other errors
    }
  }

  static String minutesToString(Map<String, int>? timeMap) {
    if (timeMap?['days'] == 0 && timeMap?['hours'] == 0) {
      if (timeMap?['minutes'] == 0) {
        return "Now";
      }
      else {
        String minutes = timeMap?['minutes'].toString() ?? "";
        return "$minutes min";
      }
    } else {
      return "";
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
}