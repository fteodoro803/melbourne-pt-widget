import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';
import 'package:flutter_project/palettes.dart';

/// Represents the colours a route can have.
class Colours {
  final String colour;
  final String textColour;

  const Colours(this.colour, this.textColour);
}

extension RouteHelpers on AppDatabase {
  Future<RoutesCompanion> createRouteCompanion({required int id, required String name, required String number, required int routeTypeId, required String gtfsId, required String status})
  async {
    AppDatabase db = Get.find<AppDatabase>();
    String? routeType = await db.getRouteTypeNameFromRouteTypeId(routeTypeId);
    Colours routeColours = setRouteColour(routeType!, number: number, name: name);

    return RoutesCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      number: drift.Value(number),
      routeTypeId: drift.Value(routeTypeId),
      colour: drift.Value(routeColours.colour),
      textColour: drift.Value(routeColours.textColour),
      gtfsId: drift.Value(gtfsId),
      status: drift.Value(status),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRoute(int id, String name, String number, int routeType, String gtfsId, String status) async {
    RoutesCompanion route = await createRouteCompanion(id: id, name: name, number: number, routeTypeId: routeType, gtfsId: gtfsId, status: status);
    AppDatabase db = Get.find<AppDatabase>();
    await db.insertRoute(route);
  }

  /// Gets routes according to name.
  Future<List<Route>> getRoutes({String? search, int? routeType}) async {
    AppDatabase db = Get.find<AppDatabase>();

    drift.SimpleSelectStatement<$RoutesTable, Route> query;
    if (search != null && search.isNotEmpty && routeType != null) {
      query = db.select(db.routes)
      ..where((tbl) => tbl.name.contains(search) & tbl.routeTypeId.equals(routeType));
    }
    else if (routeType != null) {
      query = db.select(db.routes)
        ..where((tbl) => tbl.routeTypeId.equals(routeType));
    }
    else if (search != null && search.isNotEmpty) {
      query = db.select(db.routes)
        ..where((tbl) => tbl.name.contains(search));
    }
    else {
      query = db.select(db.routes);
    }

    final result = await query.get();
    return result;
  }

  /// Sets a route's colours based on its type.
  /// Uses predefined colour palette with fallbacks for routes.
  // todo: move this to domain model
  Colours setRouteColour(String routeType, {String? name, String? number}) {
    String colour;
    String textColour;
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
      String? routeName = name?.replaceAll(" ", "").toLowerCase();

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

    return Colours(colour, textColour);
  }
}