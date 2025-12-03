import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/services/ptv_service.dart';
import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_project/palettes.dart';
import 'package:flutter_project/database/database.dart' as db;

part 'route.g.dart';

/// Represents PTV's route, with identification and styling information.
/// Handles colour mapping based on route type.
@JsonSerializable()
class Route {
  int id;
  String name;
  String
      number; // todo: should this be an int? Maybe nullable, since train doesnt have a number
  String?
      colour; // Hex colour code for background       // todo: maybe this shouldn't be optional? Since if there is no colour, it'll always use a fallback
  String? textColour; // Hex colour code for text
  RouteType type;
  String gtfsId;
  String status;

  List<Direction>? directions;
  List<Stop>? stopsAlongRoute;

  /// Creates a route object, and matches its details to its respective colour.
  Route(
      {required this.id,
      required this.name,
      required this.number,
      required this.type,
      required this.gtfsId,
      required this.status}) {
    setRouteColour(type.name);
  }

  /// Factory method to initialise a Route with async [directions] and [stopsAlongRoute]
  static Future<Route> withDetails(
      {required int id,
      required String name,
      required String number,
      required RouteType type,
      required String gtfsId,
      required String status}) async {
    PtvService ptvService = Get.find<PtvService>();

    Route route = Route(
        id: id,
        name: name,
        number: number,
        type: type,
        gtfsId: gtfsId,
        status: status);
    route.stopsAlongRoute =
        await ptvService.stops.fetchStopsByRoute(route: route);
    route.directions = await ptvService.directions.fetchDirections(route.id);

    return route;
  }

  /// Lazy-loading directions and stopAlongRoute
  Future<void> loadDetails() async {
    if (directions == null || stopsAlongRoute == null) {
      PtvService ptvService = Get.find<PtvService>();
      directions = await ptvService.directions.fetchDirections(id);
      stopsAlongRoute = await ptvService.stops.fetchStopsByRoute(route: this);
    }
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
        "\t ID: $id\t"
        "\t Type: ${type.name}\t"
        "\t Number: $number\t"
        "\t Name: $name\n"
        "\t Colour: $colour\t"
        "\t TextColour: $textColour\n"
        "\t GtfsId: $gtfsId\t"
        "\t Status: $status\n";

    if (directions != null && directions!.isNotEmpty) {
      str +=
          "\t Directions: ${directions!.map((direction) => direction.id).toList()}\n";
    }

    if (stopsAlongRoute != null && stopsAlongRoute!.isNotEmpty) {
      str +=
          "\t Stops along Route: ${stopsAlongRoute!.map((stop) => stop.id).toList()}\n";
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

  // /// Factory constructor to create a Route from a database RoutesData object.
  // factory Route.fromDb(db.RoutesTableData dbRoute) {
  //   return Route(
  //     id: dbRoute.id,
  //     name: dbRoute.name,
  //     number: dbRoute.number,
  //     gtfsId: "PLACEHOLDER",
  //     type: RouteType.fromId(dbRoute.routeTypeId),
  //     status: dbRoute.status,
  //   );
  // }

  /// Async Factory constructor to create a Route from the Database.
  static Future<Route?> fromDbAsync(db.RoutesTableData dbRoute) async {
    db.Database database = Get.find<db.Database>();
    String? gtfsId = await database.routeMapsDao.convertToGtfsRouteId(dbRoute.id);
    if (gtfsId == null) return null;

    return Route(
      id: dbRoute.id,
      name: dbRoute.name,
      number: dbRoute.number,
      type: RouteType.fromId(dbRoute.routeTypeId),
      gtfsId: gtfsId,
      status: dbRoute.status,
    );
  }
}
