import 'package:json_annotation/json_annotation.dart';

part 'route_direction_info.g.dart';

/// Represents a direction of travel for a route.
@JsonSerializable()
class RouteDirection {
  int id;
  String name;
  String description;
  // RouteType type;       // todo: in the directions API, there is an attribute for type. Maybe there are some routes with different routeTypes depending on direction?

  RouteDirection(
      {required this.id, required this.name, required this.description});

  @override
  String toString() {
    return "Route Direction:\n"
        "\tID: $id\t"
        "\tName: $name\n";
  }

  /// Factory constructor to create a Direction from the PTV API response
  factory RouteDirection.fromApi(Map<String, dynamic> json) {
    return RouteDirection(
        id: json["direction_id"],
        name: json["direction_name"],
        description: json["route_direction_description"],
    );
  }

  // Methods for JSON Serialization
  factory RouteDirection.fromJson(Map<String, dynamic> json) =>
      _$RouteDirectionFromJson(json);
  Map<String, dynamic> toJson() => _$RouteDirectionToJson(this);
}
