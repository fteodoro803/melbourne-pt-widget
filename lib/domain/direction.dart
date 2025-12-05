import 'package:flutter_project/database/database.dart' as db;

/// Represents a direction of travel for a route.
class Direction {
  int id;
  String name;
  String description;
  // RouteType type;       // todo: in the directions API, there is an attribute for type. Maybe there are some routes with different routeTypes depending on direction?

  Direction({required this.id, required this.name, required this.description});

  @override
  String toString() {
    return "Direction:\n"
        "\tID: $id\t"
        "\tName: $name\n";
  }

  /// Factory constructor to create a Direction from the PTV API response
  factory Direction.fromApi(Map<String, dynamic> json) {
    return Direction(
      id: json["direction_id"],
      name: json["direction_name"],
      description: json["route_direction_description"],
    );
  }

  /// Factory constructor to create a Direction from a database DirectionData object
  factory Direction.fromDb(db.DirectionsTableData dbDirection) {
    return Direction(
        id: dbDirection.id,
        name: dbDirection.name,
        description: dbDirection.description);
  }
}
