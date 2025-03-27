import 'package:json_annotation/json_annotation.dart';

part 'route_type_info.g.dart';


enum RouteTypeEnum {
  train(0, "train"),
  tram(1, "tram"),
  bus(2, "bus"),
  vLine(3, "vLine"),
  nightBus(4, "night bus");

  final int id;
  final String name;

  const RouteTypeEnum(this.id, this.name);
}

@JsonSerializable()
class RouteType {
  RouteTypeEnum type;

  RouteType({required this.type});
  RouteType.withTypeId({required int id})
    : type = RouteTypeEnum.values.firstWhere(
            (routeType) => routeType.id == id,
        orElse: () => throw ArgumentError('( route_type_info.dart -> RouteType.withId() ) -- No RouteTypeEnum found for id: $id')
    );
  // RouteType.withString

  @override
  String toString() {
    return "RouteType:\n"
        "\tType: ${type.id}\t"
        "\tName: ${type.name}\n";
  }

  // Convert RouteType name to type, and vice versa

  // Methods for JSON Serialization
  factory RouteType.fromJson(Map<String, dynamic> json) => _$RouteTypeFromJson(json);
  Map<String, dynamic> toJson() => _$RouteTypeToJson(this);
}