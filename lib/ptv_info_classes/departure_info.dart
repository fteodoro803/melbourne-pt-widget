import 'package:json_annotation/json_annotation.dart';

part 'departure_info.g.dart';

/// Represents a transport's departure, with information on its respective vehicle.
/// Handles conversion from UTC time to Melbourne's local time
@JsonSerializable()
class Departure {
  // Departures in UTC Time
  DateTime? scheduledDepartureUTC;
  DateTime? estimatedDepartureUTC;

  // Departures in Melbourne Time
  DateTime? scheduledDeparture;
  DateTime? estimatedDeparture;

  // Departures as a formatted String
  String? scheduledDepartureTime;
  String? estimatedDepartureTime;

  // Vehicle Descriptions
  String? runRef;
  bool? hasLowFloor;
  bool? hasAirConditioning;

  // Stop Description     // todo: i feel like there's a smarter way to do this. Stop name being here seems redundant. It's only used in fetchPattern.
  String? stopName;
  int? stopId;
  // todo: add attribute for if a stop has a high platform

  /// Creates a Departure object from a scheduled and estimated departure time in UTC.
  /// Also converts the UTC departure times to Melbourne time.
  Departure(
      {required this.scheduledDepartureUTC,
      required this.estimatedDepartureUTC,
      required this.runRef,
      required this.hasLowFloor,
      required this.hasAirConditioning,
      this.stopId}) {
    // Adds and converts Departure to local Melbourne Time
    if (scheduledDepartureUTC != null) {
      scheduledDeparture = scheduledDepartureUTC!.toLocal();
      scheduledDepartureTime = getTime(scheduledDeparture);
    }

    if (estimatedDepartureUTC != null) {
      estimatedDeparture = estimatedDepartureUTC!.toLocal();
      estimatedDepartureTime = getTime(estimatedDeparture);
    }
  }

  /// Returns a more human-readable time string from a DateTime object.
  /// 2025-04-01T05:11:00.000Z becomes 04:11pm
  String? getTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    // Converts from 24-hour to 12-hour time
    String hour;
    String minute = dateTime.minute.toString();
    String meridiem;

    if (dateTime.hour > 12) {
      hour = (dateTime.hour - 12).toString();
      meridiem = "pm";
    } else if (dateTime.hour == 12) {
      hour = "12";
      meridiem = "pm";
    } else if (dateTime.hour == 0) {
      hour = "12";
      meridiem = "am";
    } else {
      hour = dateTime.hour.toString();
      meridiem = "am";
    }

    // Adds a '0' to the left, if hour is a single digit (ex: 7 becomes 07)
    hour = hour.padLeft(2, "0");
    minute = minute.padLeft(2, "0");

    return "$hour:$minute$meridiem";
  }

  @override
  String toString() {
    return "Departures:\n"
        "\tScheduled Departure: $scheduledDeparture\t"
        "\tEstimated Departure: $estimatedDeparture\n"
        "\tRun Ref: $runRef\t"
        "\tLow Floor: $hasLowFloor\t"
        "\tStop Name ($stopId): $stopName\n";
  }

  /// Methods for JSON Serialization
  factory Departure.fromJson(Map<String, dynamic> json) =>
      _$DepartureFromJson(json);
  Map<String, dynamic> toJson() => _$DepartureToJson(this);
}
