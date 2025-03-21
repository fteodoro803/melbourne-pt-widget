import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransportUtils {
  // Function to compare estimated and scheduled departure times for a transport departure
  static String getDepartureStatus(String? estimatedDepartureTime, String? scheduledDepartureTime) {
    if (estimatedDepartureTime == null || scheduledDepartureTime == null) {
      return "Scheduled"; // Default to On-time if either value is null
    }

    // Convert the time strings to DateTime objects for comparison
    var formatter = DateFormat('hh:mma'); // Adjust the format according to your input time format

    try {
      DateTime estimatedTime = formatter.parse(estimatedDepartureTime.toUpperCase());
      DateTime scheduledTime = formatter.parse(scheduledDepartureTime.toUpperCase());

      // Compare the times
      if (estimatedTime.isAfter(scheduledTime)) {
        return "Departed late"; // Estimated departure is later than scheduled, so it's late
      } else if (estimatedTime.isBefore(scheduledTime)) {
        return "Departed early"; // Estimated departure is earlier than scheduled, so it's early
      } else {
        return "On time"; // Both times are the same, so it's on-time
      }
    } catch (e) {
      return "Scheduled"; // Default to "On-time" if there is any error in parsing the time
    }
  }

  // Function to return color based on departure status
  static Color getColorForStatus(String status) {
    switch (status) {
      case "Departed late":
        return Color(0xFF8A0000); // Red for late
      case "Departed early":
        return Color(0xFFA39541); // Yellow for early
      case "On time":
        return Color(0xFF138800); // Yellow for early
      case "Scheduled":
      default:
        return Colors.black; // Green for on-time or default
    }
  }
}

class TimeUtils {
  // Finds time difference in days and minutes between system time and given departure time
  static Map<String, int>? timeDifference(String inputTime) {
    try {
      // Convert the input time to uppercase to handle lowercase am/pm
      inputTime = inputTime.toUpperCase();

      // Set the input time format
      var formatter = DateFormat('hh:mma');

      // Parse the input time string into a DateTime object
      DateTime inputDate = formatter.parse(inputTime);

      // Get current system time
      DateTime currentDate = DateTime.now();

      // Set the same date for the input time (same year, month, day as the current system time)
      DateTime fullInputDate = DateTime(currentDate.year, currentDate.month, currentDate.day,
          inputDate.hour, inputDate.minute);

      // Find the difference between current time and the input time
      Duration difference = fullInputDate.difference(currentDate);

      // Get the days and minutes from the difference
      int days = difference.inDays;
      int minutes = difference.inMinutes % 60; // Get the remaining minutes

      return {'days': days, 'minutes': minutes};
    } catch (e) {
      return null; // If the input format is incorrect or other errors
    }
  }

  static String minutesToString(String minutes) {
    if (minutes == "0") {
      return "Now";
    } else if (minutes != "" && int.parse(minutes) > 0 && int.parse(minutes) < 60) {
      return "$minutes min";  // Display nothing if more than 60 minutes
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