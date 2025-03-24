import 'package:json_annotation/json_annotation.dart';

part 'route_type_info.g.dart';

@JsonSerializable()
class RouteType {
  String name;      // consider changing the ? to late
  String type;   // 0 - train, 1 - tram, etc

  RouteType({required this.name, required this.type});

  @override
  String toString() {
    return "RouteType:\n"
        "\tType: $type\t"
        "\tName: $name\n";
  }

  // Methods for JSON Serialization
  factory RouteType.fromJson(Map<String, dynamic> json) => _$RouteTypeFromJson(json);
  Map<String, dynamic> toJson() => _$RouteTypeToJson(this);
}