import 'package:flutter_project/add_screens/controllers/search_controller.dart' as search_controller;
import 'package:get/get.dart';

import '../lib/domain/route.dart' as pt_route;
import '../lib/domain/stop.dart';
import '../lib/add_screens/utility/search_utils.dart';

class RouteDetailsController extends GetxController {
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  SearchUtils searchUtils = SearchUtils();
  RxList<SuburbStops> suburbStops = <SuburbStops>[].obs;
  late pt_route.Route route;
  late String direction;
  final directionReversed = false.obs;


  Stop? findMatchingStop(Stop targetStop) {
    for (var suburb in suburbStops) {
      for (var stop in suburb.stops) {
        if (stop.id == targetStop.id) {
          return stop;
        }
      }
    }
    return null;
  }

  Future<void> getSuburbStops() async {
    pt_route.Route route = searchController.details.value.route!;
    List<Stop> stopsAlongRoute = route.stopsAlongRoute!;
    List<SuburbStops> newSuburbStops = await searchUtils.getSuburbStops(stopsAlongRoute, route);

    suburbStops.assignAll(newSuburbStops);
  }

  void changeDirection() {
    directionReversed.value = !directionReversed.value;
      for (var suburb in suburbStops) {
        suburb.stops = suburb.stops.reversed.toList();
      }
      suburbStops.assignAll(suburbStops.reversed.toList());
      direction = direction == route.directions![0].name ? route.directions![1].name : route.directions![0].name;
  }

  @override
  void onInit() {
    super.onInit();
    route = searchController.details.value.route!;

    if (route.directions != null && route.directions!.isNotEmpty) {
      direction = route.directions![0].name;
    }

    getSuburbStops();
  }
}