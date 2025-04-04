import 'package:drift/drift.dart' as drift;
import '../database.dart';
import 'package:get/get.dart';

extension RouteHelpers on AppDatabase {
  Future<RoutesCompanion> createRouteCompanion({required int id, required String name, int? number, int? routeTypeId})

  // todo: get colours here

  async {
    return RoutesCompanion(
      id: drift.Value(id),
      name: drift.Value(name),
      number: drift.Value(number),
      routeTypeId: drift.Value(routeTypeId),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  Future<void> addRoute(int id, String name, {int? number, int? routeTypeId}) async {
    RoutesCompanion route = await createRouteCompanion(id: id, name: name, number: number, routeTypeId: routeTypeId);
    AppDatabase db = Get.find<AppDatabase>();
    db.insertRoute(route);
  }

  // /// Sets a route's colours based on its type.
  // /// Uses predefined colour palette with fallbacks for routes.
  // // todo: convert the string routeType to a RouteTypeEnum
  // void setRouteColour(String routeType) {
  //   routeType = routeType.toLowerCase(); // Normalise case for matching
  //
  //   // Tram routes: match by route number
  //   if (routeType == "tram") {
  //     String routeId = "route$number";
  //
  //     colour = TramPalette.values
  //         .firstWhere((route) => route.name == routeId,
  //         orElse: () => TramPalette.routeDefault)
  //         .colour;
  //     textColour = TramPalette.values
  //         .firstWhere((route) => route.name == routeId,
  //         orElse: () => TramPalette.routeDefault)
  //         .textColour
  //         .colour;
  //   }
  //
  //   // Train routes: match by route name
  //   else if (routeType == "train") {
  //     String routeName = name.replaceAll(" ", "").toLowerCase();
  //
  //     // Matches Transport route name to Palette route Name
  //     colour = TrainPalette.values
  //         .firstWhere((route) => route.name == routeName,
  //         orElse: () => TrainPalette.routeDefault)
  //         .colour;
  //     textColour = TrainPalette.values
  //         .firstWhere((route) => route.name == routeName,
  //         orElse: () => TrainPalette.routeDefault)
  //         .textColour
  //         .colour;
  //   }
  //
  //   // Bus and Night Bus routes: use standard colours
  //   // todo: add route-specific colours
  //   else if (routeType == "bus" || routeType == "night bus") {
  //     colour = BusPalette.routeDefault.colour;
  //     textColour = BusPalette.routeDefault.textColour.colour;
  //   }
  //
  //   // VLine routes: use standard colours
  //   // todo: add route-specific colours
  //   else if (routeType == "vline") {
  //     colour = VLine.routeDefault.colour;
  //     textColour = VLine.routeDefault.textColour.colour;
  //
  //     // Unknown route type: use fallback colours
  //   } else {
  //     colour = FallbackColour.routeDefault.colour;
  //     textColour = FallbackColour.routeDefault.textColour.colour;
  //   }
  // }
}