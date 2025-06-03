import 'package:flutter_project/database/helpers/stop_helpers.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/route_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:get/get.dart';

part 'stop.g.dart';

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
  String? landmark;

  Stop({required this.id, required this.name, required this.latitude, required this.longitude, this.distance, this.suburb, this.stopSequence, this.landmark});   // todo: probably make these constructors more distinct
  Stop.withSequence({required this.id, required this.name, required this.latitude, required this.longitude, this.distance, required this.stopSequence, this.landmark, this.suburb});

  @override
  String toString() {
    return "Stop:\n"
        "\tID: $id\t"
        "\tName: $name\n"
        "\tLatitude: $latitude\t"
        "\tLongitude: $longitude\t"
        "\tDistance: $distance\n"
        "\tRoutes: $routes\t"
        "\tRouteType: $routeType\t"
        "\tStopSequence: $stopSequence\n"
        "\tSuburb: $suburb\t"
        "\tLandmark: $landmark\n";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Stop && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Factory constructor to create a Route from the PTV API response
  factory Stop.fromApi(Map<String, dynamic> json) {
    return Stop(
      id: json["stop_id"],
      name: json["stop_name"],
      latitude: json["stop_latitude"],
      longitude: json["stop_longitude"],
      distance: json["stop_distance"],
      suburb: json["stop_suburb"],
      stopSequence: json["stop_sequence"],
      landmark: json["stop_landmark"],
    );
  }

  // Methods for Database
  /// Factory constructor from database
  // todo: get sequence data
  factory Stop.fromDb({required db.StopsTableData dbStop, int? sequence}) {
    return Stop.withSequence(
        id: dbStop.id,
        name: dbStop.name,
        latitude: dbStop.latitude,
        longitude: dbStop.longitude,
        // stopSequence: dbStop.sequence,
        stopSequence: sequence,
        landmark: dbStop.landmark,
        suburb: dbStop.suburb,
    );
  }

  /// Constructor from database, by ID
  static Future<Stop?> fromId(int id) async {
    db.StopsTableData? dbStop = await Get.find<db.AppDatabase>().getStopById(id);
    return dbStop != null ? Stop.fromDb(dbStop: dbStop) : null;       // todo: maybe get sequence? or maybe better to keep without sequence, since it doesn't have context
  }

  // Methods for JSON Serialization
  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
  Map<String, dynamic> toJson() => _$StopToJson(this);
}