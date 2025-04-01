import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_project/palettes.dart';

part 'route_info.g.dart';

@JsonSerializable()
class Route {
  int id;
  String name;
  String number;
  String? colour;
  String? textColour;

  RouteDirection? direction;
  RouteType type;

  Route(
      {required this.id,
      required this.name,
      required this.number,
      required this.type}) {
    setRouteColour(type.type.name);
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

  // Sets this route's Colour according to Palette
  void setRouteColour(String routeType) {
    routeType = routeType.toLowerCase(); // improve case matching

    // Tram
    if (routeType == "tram") {
      String routeId = "route$number";

      // print("( route_info.dart -> getRouteColour() ) -- Tram routeId: $routeId");

      // Matches Transport route number to Palette route Name
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

    // Train
    else if (routeType == "train") {
      String routeName = name.replaceAll(" ", "").toLowerCase();
      // print("( route_info.dart -> getRouteColour() ) -- routeName conversion: $name -> $routeName");

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

    // Bus and Night Bus
    else if (routeType == "bus" || routeType == "night bus") {
      colour = BusPalette.routeDefault.colour;
      textColour = BusPalette.routeDefault.textColour.colour;
    }

    // VLine
    else if (routeType == "vline") {
      colour = VLine.routeDefault.colour;
      textColour = VLine.routeDefault.textColour.colour;
    } else {
      // print("( route_info.dart -> getRouteColour() ) -- Fallback colour used");
      colour = FallbackColour.routeDefault.colour;
      textColour = FallbackColour.routeDefault.textColour.colour;
    }
  }

  // Methods for JSON Serialization
  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);
}
