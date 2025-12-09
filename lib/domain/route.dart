import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/services/ptv_service.dart';
import 'package:get/get.dart';
import 'package:flutter_project/database/database.dart' as db;

/// Represents PTV's route, with identification and styling information.
/// Handles colour mapping based on route type.
class Route {
  int id;
  String name;
  String number; // should this be an int? Maybe nullable, since train doesnt have a number
  RouteType type;
  String status;

  // Lazy loaded details
  bool isLoaded = false;
  String gtfsId = "";  // make gtfsId nullable?
  String? colour; // Hex colour code for background
  String? textColour; // Hex colour code for text
  List<Direction>? directions;
  List<Stop>? stopsAlongRoute;

  /// Creates a route object, and matches its details to its respective colour.
  Route(
      {required this.id,
      required this.name,
      required this.number,
      required this.type,
      required this.status});

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
        status: status);
    route.stopsAlongRoute =
        await ptvService.stops.fetchStopsByRoute(route: route);
    route.directions = await ptvService.directions.fetchDirections(route.id);

    return route;
  }

  /// Lazy-loading directions and stopAlongRoute
  Future<void> loadDetails() async {
    var ptvService = Get.find<PtvService>();
    directions = await ptvService.directions.fetchDirections(id);
    stopsAlongRoute = await ptvService.stops.fetchStopsByRoute(route: this);

    var database = Get.find<db.Database>();
    gtfsId = await database.routeMapsDao.convertToGtfsRouteId(id) ?? "EMPTY";
    var gtfsRoute = await database.gtfsRoutesDao.getRoute(gtfsId);
    if (gtfsRoute == null) {
      print("( route.dart -> loadDetails ) -- gtfsRoute is null");
      return;
    }
    colour = gtfsRoute.colour;
    textColour = gtfsRoute.textColour;

    isLoaded = true;
  }

  // Override == operator to compare routes based on the routeNumber.
  @override
  bool operator == (Object other) {
    if (identical(this, other)) return true;
    return other is Route && other.id == id;
  }

  // Override hashCode based on routeNumber for proper comparison in collections like Set
  @override
  int get hashCode => id.hashCode;

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

  /// Factory constructor to create a Route from the PTV API response
  factory Route.fromApi(Map<String, dynamic> json) {
    return Route(
      id: json["route_id"],
      name: json["route_name"],
      number: json["route_number"],
      type: RouteType.fromId(json["route_type"]),
      status: json["route_service_status"]["description"],
    );
  }

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
      status: dbRoute.status,
    );
  }
}
