import 'package:json_annotation/json_annotation.dart';

/// Enumerator representing the route types available via PTV
@JsonEnum()
enum RouteTypeEnum {
  @JsonValue(0)
  train(0, "train"),

  @JsonValue(1)
  tram(1, "tram"),

  @JsonValue(2)
  bus(2, "bus"),

  @JsonValue(3)
  vLine(3, "vLine");

  // @JsonValue(4)
  // nightBus(4, "night bus");      // reenable nightbus later, or merge with bus

  final int id;
  final String name;

  //Constructors
  const RouteTypeEnum(this.id, this.name);

  /// Factory constructor for a route type via id (ie. 0, 1).
  static RouteTypeEnum fromId(int id) {
    return RouteTypeEnum.values.firstWhere(
            (routeType) => routeType.id == id,
        orElse: () => throw ArgumentError('No RouteType found for id: $id')
    );
  }

  /// Factory constructor for a route type via name (ie. "tram", "bus").
  static RouteTypeEnum fromName(String name) {
    return RouteTypeEnum.values.firstWhere(
            (routeType) => RouteTypeEnum._normaliseName(routeType.name) == RouteTypeEnum._normaliseName(name),
        orElse: () => throw ArgumentError('( route_type_info.dart -> RouteType.withName() ) -- No RouteTypeEnum found for name: $name')
    );
  }

  /// Helper method to normalize name for comparison
  static String _normaliseName(String name) {
    return name.toLowerCase().replaceAll(' ', '');
  }

  /// Methods for JSON Serialization
  // These methods handle conversion between RouteType and JSON representation
  static RouteTypeEnum fromJson(int json) => fromId(json);
  int toJson() => id;
}