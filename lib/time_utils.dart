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
        return "Late"; // Estimated departure is later than scheduled, so it's late
      } else if (estimatedTime.isBefore(scheduledTime)) {
        return "Early"; // Estimated departure is earlier than scheduled, so it's early
      } else {
        return "On-time"; // Both times are the same, so it's on-time
      }
    } catch (e) {
      return "Scheduled"; // Default to "On-time" if there is any error in parsing the time
    }
  }

  // Function to return color based on departure status
  static Color getColorForStatus(String status) {
    switch (status) {
      case "Late":
        return Colors.red; // Red for late
      case "Early":
        return Colors.yellow; // Yellow for early
      case "On-time":
        return Colors.green; // Yellow for early
      case "Scheduled":
      default:
        return Colors.black; // Green for on-time or default
    }
  }
}

class TimeDifference {
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
}