import 'package:flutter_project/ptv_info_classes/route_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:json_annotation/json_annotation.dart';

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
  int? stopSequence;

  // todo: maybe use the Location class; im not sure if these should be here
  double? latitude;
  double? longitude;
  double? distance;
  String? suburb;

  Stop({required this.id, required this.name, required this.latitude, required this.longitude, this.distance, this.suburb, this.stopSequence});

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

  // Methods for JSON Serialization
  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
  Map<String, dynamic> toJson() => _$StopToJson(this);
}