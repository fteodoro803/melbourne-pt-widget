import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_project/palettes.dart';

part 'route_info.g.dart';

/// Represents PTV's route, with identification and styling information.
/// Handles colour mapping based on route type.
@JsonSerializable()
class Route {
  int id;
  String name;
  String number;
  String? colour;       // Hex colour code for background
  String? textColour;   // Hex colour code for text

  RouteDirection? direction;
  RouteType type;

  Route(
      {required this.id,
      required this.name,
      required this.number,
      required this.type}) {
    setRouteColour(type.type.name);
  }

  /// Sets a route's colours based on its type.
  /// Uses predefined colour palette with fallbacks for routes.
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
        "\tID: $id\t"
        "\tName: $name\t"
        "\tNumber: $number\n"
        "\tColour: $colour\t"
        "\tTextColour: $textColour\n";

    if (direction != null) {
      str += direction.toString();
    }

    return str;
  }

  /// Methods for JSON Serialization.
  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);
}
