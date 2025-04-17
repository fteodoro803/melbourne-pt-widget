import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_project/palettes.dart';
import 'package:flutter_project/database/database.dart' as db;

part 'route_info.g.dart';

/// Represents PTV's route, with identification and styling information.
/// Handles colour mapping based on route type.
@JsonSerializable()
class Route {
  int id;
  String name;
  String number;        // todo: should this be an int? Maybe nullable, since train doesnt have a number
  String? colour;       // Hex colour code for background       // todo: maybe this shouldn't be optional? Since if there is no colour, it'll always use a fallback
  String? textColour;   // Hex colour code for text
  RouteType type;
  String gtfsId;
  String status;

  List<RouteDirection>? directions;
  List<Stop>? stopsAlongRoute;

  /// Creates a route object, and matches its details to its respective colour.
  Route(
      {required this.id,
      required this.name,
      required this.number,
      required this.type, required this.gtfsId, required this.status}) {
    setRouteColour(type.name);
  }

  // Override == operator to compare routes based on the routeNumber.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Route && other.id == id;
  }

  // Override hashCode based on routeNumber for proper comparison in collections like Set
  @override
  int get hashCode => id.hashCode;

  /// Sets a route's colours based on its type.
  /// Uses predefined colour palette with fallbacks for routes.
  // todo: convert the string routeType to a RouteTypeEnum
  void setRouteColour(String routeType) {
    routeType = routeType.toLowerCase(); // Normalise case for matching

    // Tram routes: match by route number
    if (routeType == "tram") {
      String routeId = "route$number";

      colour = TramPalette.values
          .firstWhere((route) => route.name == routeId,
              orElse: () => TramPalette.routeDefault)
          .colour;
      textColour = TramPalette.values
          .firstWhere((route) => route.name == routeId,
              orElse: () => TramPalette.routeDefault)
          .textColour
          .colour;
    }

    // Train routes: match by route name
    else if (routeType == "train") {
      String routeName = name.replaceAll(" ", "").toLowerCase();

      // Matches Transport route name to Palette route Name
      colour = TrainPalette.values
          .firstWhere((route) => route.name == routeName,
              orElse: () => TrainPalette.routeDefault)
          .colour;
      textColour = TrainPalette.values
          .firstWhere((route) => route.name == routeName,
              orElse: () => TrainPalette.routeDefault)
          .textColour
          .colour;
    }

    // Bus and Night Bus routes: use standard colours
    // todo: add route-specific colours
    else if (routeType == "bus" || routeType == "night bus") {
      colour = BusPalette.routeDefault.colour;
      textColour = BusPalette.routeDefault.textColour.colour;
    }

    // VLine routes: use standard colours
    // todo: add route-specific colours
    else if (routeType == "vline") {
      colour = VLine.routeDefault.colour;
      textColour = VLine.routeDefault.textColour.colour;

    // Unknown route type: use fallback colours
    } else {
      colour = FallbackColour.routeDefault.colour;
      textColour = FallbackColour.routeDefault.textColour.colour;
    }
  }

  @override
  String toString() {
    String str = "Route:\n"
        "\t         ID: $id\t"
        "\t     Number: $number\t"
        "\t       Name: $name\n"
        "\t       Type: ${type.name}\t"
        "\t     Colour: $colour\t"
        "\t TextColour: $textColour\n"
        "\t     GtfsId: $gtfsId\t"
        "\t     Status: $status\n"
    ;

    if (direction != null) {
      str += direction.toString();
    }

    return str;
  }

  /// Methods for JSON Serialization.
  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);

  /// Factory constructor to create a Route from the PTV API response
  factory Route.fromApi(Map<String, dynamic> json) {
    return Route(
        id: json["route_id"],
        name: json["route_name"],
        number: json["route_number"],
        type: RouteType.fromId(json["route_type"]),
        gtfsId: json["route_gtfs_id"],
        status: json["route_service_status"]["description"],
    );
  }

  /// Factory constructor to create a Route from a database RoutesData object.
  factory Route.fromDb(db.RoutesTableData dbRoute) {
    return Route(
      id: dbRoute.id,
      name: dbRoute.name,
      number: dbRoute.number,
      type: RouteType.fromId(dbRoute.routeTypeId),
      gtfsId: dbRoute.gtfsId,
      status: dbRoute.status,
    );
  }
}
