import 'package:json_annotation/json_annotation.dart';

part 'route_direction_info.g.dart';

/// Represents a direction of travel for a route.
@JsonSerializable()
class RouteDirection {
  int id;
  String name;
  String description;

  RouteDirection(
      {required this.id, required this.name, required this.description});

  @override
  String toString() {
    return "Route Direction:\n"
        "\tID: $id\t"
        "\tName: $name\n";
  }

  // Methods for JSON Serialization
  factory RouteDirection.fromJson(Map<String, dynamic> json) =>
      _$RouteDirectionFromJson(json);
  Map<String, dynamic> toJson() => _$RouteDirectionToJson(this);
}
