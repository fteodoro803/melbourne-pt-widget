import 'package:json_annotation/json_annotation.dart';

part 'departure_info.g.dart';

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
  String? runId;
  String? runRef;
  bool? hasLowFloor;

  // Constructor
  Departure({required this.scheduledDepartureUTC, required this.estimatedDepartureUTC, required this.runId, required this.runRef}) {

    // Adds and converts Departure to local Melbourne Time
    if (scheduledDepartureUTC != null){
      scheduledDeparture = scheduledDepartureUTC!.toLocal();
      scheduledDepartureTime = getTime(scheduledDeparture);
    }

    if (estimatedDepartureUTC != null) {
      estimatedDeparture = estimatedDepartureUTC!.toLocal();
      estimatedDepartureTime = getTime(estimatedDeparture);
    }
  }

  // Returns the formatted Time String from a DateTime variable
  String? getTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    // Converts 24 hour time to 12
    String hour;
    String minute = dateTime.minute.toString();
    String meridiem;

    if (dateTime.hour > 12) {
      hour = (dateTime.hour - 12).toString();
      meridiem = "pm";
    }
    else {
      hour = dateTime.hour.toString();
      meridiem = "am";
    }

    // Adds a '0' to the left, if Single digit time (ex: 7 becomes 07)
    hour = hour.padLeft(2, "0");
    minute = minute.padLeft(2, "0");

    return "$hour:$minute$meridiem";
  }

  @override
  String toString() {
    return "Departures:\n"
      "\tScheduled Departure: $scheduledDeparture\n"
      "\tEstimated Departure: $estimatedDeparture\n"
      "\tRun ID, Ref: $runId, $runRef\n"
      "\tLow Floor: $hasLowFloor\n"
    ;
  }

  // Methods for JSON Serialization
  factory Departure.fromJson(Map<String, dynamic> json) => _$DepartureFromJson(json);
  Map<String, dynamic> toJson() => _$DepartureToJson(this);
}