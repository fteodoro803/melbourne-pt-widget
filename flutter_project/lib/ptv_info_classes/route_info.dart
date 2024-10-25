import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'route_info.g.dart';

@JsonSerializable()
class Route {
  String id;
  String name;
  String number;

  RouteDirection? direction;

  Route({required this.id, required this.name, required this.number});

  @override
  String toString() {
    String str = "Route:\n"
        "\tID: $id\n"
        "\tName: $name \n"
        "\tNumber: $number\n";

    if (direction != null) {
      str += direction.toString();
    }

    return str;
  }

  // Methods for JSON Serialization
  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);
}