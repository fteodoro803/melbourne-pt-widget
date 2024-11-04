// Random Utility Functions

// Returns the Time from a DateTime variable
String? getTime(DateTime? dateTime) {
  if (dateTime == null) {
    return null;
  }

  // Adds a '0' to the left, if Single digit time (ex: 7 becomes 07)
  String hour = dateTime.hour.toString().padLeft(2, "0");
  String minute = dateTime.minute.toString().padLeft(2, "0");

  return "$hour:$minute";
}