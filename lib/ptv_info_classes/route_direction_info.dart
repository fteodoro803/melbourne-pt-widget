import 'package:json_annotation/json_annotation.dart';

part 'route_direction_info.g.dart';

@JsonSerializable()
class RouteDirection {
  String id;        // todo: change this to an int
  String name;
  String description;

  RouteDirection({required this.id, required this.name, required this.description});

  @override
  String toString() {
    return "Route Direction:\n"
        "\tID: $id\t"
        "\tName: $name\n";
  }

  // Methods for JSON Serialization
  factory RouteDirection.fromJson(Map<String, dynamic> json) => _$RouteDirectionFromJson(json);
  Map<String, dynamic> toJson() => _$RouteDirectionToJson(this);
}