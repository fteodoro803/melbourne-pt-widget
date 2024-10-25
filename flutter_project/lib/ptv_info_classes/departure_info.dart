// idk if this needs to be stored~

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

  String? runId;
  String? runRef;

  // Constructor
  Departure({required this.scheduledDepartureUTC, required this.estimatedDepartureUTC}) {

    if (scheduledDepartureUTC != null){
    scheduledDeparture = scheduledDepartureUTC!.toLocal();
    }

    if (estimatedDepartureUTC != null) {
      estimatedDeparture = estimatedDepartureUTC!.toLocal();
    }
  }

  // Add an Update Departure Function

  @override
  String toString() {
    return "Departures:\n"
        "\tScheduled Departure: $scheduledDeparture\n"
        "\tEstimated Departure: $estimatedDeparture\n";
  }

  // Methods for JSON Serialization
  factory Departure.fromJson(Map<String, dynamic> json) => _$DepartureFromJson(json);
  Map<String, dynamic> toJson() => _$DepartureToJson(this);
}