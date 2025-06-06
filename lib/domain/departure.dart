import 'package:json_annotation/json_annotation.dart';

part 'departure.g.dart';

/// Represents a transport's departure, with information on its respective vehicle.
/// Handles conversion from UTC time to Melbourne's local time
@JsonSerializable()
class Departure {
  // Departures in UTC Time
  DateTime? scheduledDepartureUTC;
  DateTime? estimatedDepartureUTC;

  // Departures in Melbourne Time     // todo: is there a need for this? Since the departure times are already in the database. Maybe only formatted is necessary
  DateTime? scheduledDeparture;
  DateTime? estimatedDeparture;

  // Departures as a formatted String
  String? scheduledDepartureTime;
  String? estimatedDepartureTime;

  // Vehicle Descriptions
  String? runRef;     // id
  bool? hasLowFloor;
  bool? hasAirConditioning;
  String? platformNumber;

  // TimeDifference? timeDifference;
  // DepartureStatus? status;

  // Stop Description     // todo: i feel like there's a smarter way to do this. Stop name being here seems redundant. It's only used in fetchPattern.
  String? stopName;
  int? stopId;
  // todo: add attribute for if a stop has a high platform

  // todo: URGENT: add platform number

  /// Creates a Departure object from a scheduled and estimated departure time in UTC.
  /// Also converts the UTC departure times to Melbourne time.
  Departure(
      {required this.scheduledDepartureUTC,
      required this.estimatedDepartureUTC,
      required this.runRef,
      required this.hasLowFloor,
      required this.hasAirConditioning,
      this.platformNumber,
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

  /// Factory constructor to create a Departure from the PTV API response
  factory Departure.fromAPI(Map<String, dynamic> departureData, Map<String, dynamic>? runData) {
    DateTime? scheduledDepartureUTC = departureData["scheduled_departure_utc"] !=
        null ? DateTime.parse(departureData["scheduled_departure_utc"]) : null;
    DateTime? estimatedDepartureUTC = departureData["estimated_departure_utc"] !=
        null ? DateTime.parse(departureData["estimated_departure_utc"]) : null;
    String? runRef = departureData["run_ref"]?.toString();
    int? stopId = departureData["stop_id"];
    String? platformNumber = departureData["platform_number"];

    // Get Vehicle descriptors per Departure
    var vehicleDescriptors = runData?[runRef]?["vehicle_descriptor"]; // makes vehicleDescriptors null if data for "runs" and/or "runRef" doesn't exist
    bool? hasLowFloor;
    bool? hasAirConditioning;
    if (vehicleDescriptors != null && vehicleDescriptors.toString().isNotEmpty) {
      hasLowFloor = vehicleDescriptors["low_floor"];
      hasAirConditioning = vehicleDescriptors["air_conditioned"];
    }
    else {
      print(
          "( departure.dart -> Departure.fromAPI ) -- runs for runRef $runRef is empty )");
    }

    return Departure(
      scheduledDepartureUTC: scheduledDepartureUTC,
      estimatedDepartureUTC: estimatedDepartureUTC,
      runRef: runRef,
      stopId: stopId,
      hasAirConditioning: hasAirConditioning,
      hasLowFloor: hasLowFloor,
      platformNumber: platformNumber,
    );
  }

  /// Methods for JSON Serialization
  factory Departure.fromJson(Map<String, dynamic> json) =>
      _$DepartureFromJson(json);
  Map<String, dynamic> toJson() => _$DepartureToJson(this);
}
