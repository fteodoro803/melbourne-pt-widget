import 'package:flutter/cupertino.dart';
import 'package:flutter_project/add_screens/controllers/search_controller.dart' as search_controller;
import 'package:get/get.dart';

import '../../ptv_info_classes/route_info.dart' as pt_route;
import '../../ptv_info_classes/stop_info.dart';
import '../utility/search_utils.dart';

class RouteDetailsController extends GetxController {
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  SearchUtils searchUtils = SearchUtils();
  RxList<SuburbStops> suburbStops = <SuburbStops>[].obs;
  late pt_route.Route route;
  late String direction;
  final directionReversed = false.obs;

  final stopToScrollTo = Rx<Stop?>(null);
  final keysByStop = <Stop, GlobalKey>{};

// Method to request scrolling to a specific stop
  void scrollToStop(Stop stop) {
    stopToScrollTo.value = stop;
    print("Requesting scroll to: ${stop.name}");

    // Force a UI update to ensure keys are registered
    update();

    // Try multiple times with increasing delays to ensure the widget is built
    for (int delay = 100; delay <= 1000; delay += 100) {
      Future.delayed(Duration(milliseconds: delay), () {
        final key = getKeyForStop(stop);
        print(key);
        if (key.currentContext != null) {
          print("Found context for ${stop.name} at ${delay}ms, scrolling...");
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          stopToScrollTo.value = null;
        } else {
          print("No context found for ${stop.name} at ${delay}ms attempt");
        }
      });
    }
  }

// Method to get or create a key for a stop
  GlobalKey getKeyForStop(Stop stop) {
    return keysByStop.putIfAbsent(stop, () => GlobalKey());
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

  void setExpanded(SuburbStops suburb) {
    suburb.isExpanded.value = !suburb.isExpanded.value;
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