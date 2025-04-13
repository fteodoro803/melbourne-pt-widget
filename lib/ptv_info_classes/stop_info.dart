import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:drift/drift.dart' as drift;

part 'stop_info.g.dart';

/// Represents a Stop a transport can pass through.
@JsonSerializable()
class Stop {
  int id;      // convert this to integer ~note
  String name;      //~note what happens if in an api call, these are null?
  List<Route>? routes;      // todo: turn this into a method: get Routes from a Stop
  RouteType? routeType;      // todo, turn this to a list
  int? number;
  bool? isExpanded = false;
  int? stopSequence;        // todo: rename this to sequence

  // todo: maybe use the Location class; im not sure if these should be here
  double? latitude;     // todo: make these not nullable
  double? longitude;
  double? distance;     // todo: change this to a getDistance function
  String? suburb;

  Stop({required this.id, required this.name, required this.latitude, required this.longitude, this.distance, this.suburb, this.stopSequence});   // todo: probably make these constructors more distinct
  Stop.withSequence({required this.id, required this.name, required this.latitude, required this.longitude, this.distance, required this.stopSequence});

  @override
  String toString() {
    return "Stop:\n"
        "\tID: $id\t"
        "\tName: $name\n"
        "\tLatitude: $latitude\n"
        "\tLongitude: $longitude\n"
        "\tDistance: $distance\n"
        "\tRoutes: $routes\n"
        "\tRouteType: $routeType\n"
        "\tStopSequence: $stopSequence\n"
        "\tSuburb: $suburb\n";
  }

  // Methods for Database
  /// Factory constructor from database
  factory Stop.fromDb(db.StopsTableData dbStop) {
    return Stop.withSequence(
        id: dbStop.id,
        name: dbStop.name,
        latitude: dbStop.latitude,
        longitude: dbStop.longitude,
        stopSequence: dbStop.sequence,
    );
  }

  /// Converts Stop to StopsTableCompanion
  db.StopsTableCompanion toCompanion() {
    return db.StopsTableCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      latitude: latitude != null ? drift.Value(latitude!) : drift.Value(0),
      longitude: longitude != null ? drift.Value(longitude!) : drift.Value(0),
      sequence: drift.Value(stopSequence),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  // Methods for JSON Serialization
  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
  Map<String, dynamic> toJson() => _$StopToJson(this);
}