import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:json_annotation/json_annotation.dart';
import '../palettes.dart';

part 'route_info.g.dart';

@JsonSerializable()
class Route {
  String id;
  String name;
  String number;
  String? colour;

  RouteDirection? direction;

  Route({required this.id, required this.name, required this.number});

  @override
  String toString() {
    String str = "Route:\n"
        "\tID: $id\n"
        "\tName: $name \n"
        "\tNumber: $number\n"
        "\tColour: $colour\n"
    ;

    if (direction != null) {
      str += direction.toString();
    }

    return str;
  }

  // Only for trams for now
  // For testing, ensure that all the routes go to the right things
  void getRouteColour(String routeType) {
    print("( route_info.dart -> getRouteColour() ) -- routeType: $routeType");

    // Tram
    if (routeType == "Tram") {
      String routeId = "route$number";

      print("( route_info.dart -> getRouteColour() ) -- Tram routeId: $routeId");

      // Matches Transport route number to Palette route Name
      this.colour = TramPalette.values.firstWhere(
          (route) => route.name == routeId,
          orElse: () => TramPalette.routeDefault
      ).colour;
    }

    // Train
    if (routeType == "Train") {
      String routeName = name.replaceAll(" ", "").toLowerCase();
      print("( route_info.dart -> getRouteColour() ) -- routeName conversion: $name -> $routeName");

      // Matches Transport route name to Palette route Name
      this.colour = TrainPalette.values.firstWhere(
              (route) => route.name == routeName,
          orElse: () => TrainPalette.routeDefault
      ).colour;
    }

    // Bus
    if (routeType == "Bus") {
      this.colour = BusPalette.routeDefault.colour;
    }
  }

  // Methods for JSON Serialization
  factory Route.fromJson(Map<String, dynamic> json) => _$RouteFromJson(json);
  Map<String, dynamic> toJson() => _$RouteToJson(this);
}