// controllers/nearby_stops_controller.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_project/add_screens/controllers/search_controller.dart' as search_controller;
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../domain/stop.dart';
import '../utility/search_utils.dart';
import 'map_controller.dart';

enum ToggleableFilter {
  lowFloor(name: "Low Floor"),
  shelter(name: "Shelter");

  final String name;
  const ToggleableFilter({required this.name});
}

class NearbyStopsController extends GetxController {
  final search_controller.SearchController searchController = Get.find();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  RxString selectedDistance = "300".obs;
  RxString selectedUnit = "m".obs;
  RxSet<ToggleableFilter> filters = <ToggleableFilter>{}.obs;
  RxString selectedRouteType = "all".obs;
  RxList<Stop> stops = <Stop>[].obs;

  RxInt savedScrollIndex = 0.obs;

  SearchUtils searchUtils = SearchUtils();

  RxMap<String, bool> transportTypeFilters = {
    "all": true,
    "tram": false,
    "bus": false,
    "train": false,
    "vLine": false,
  }.obs;

  List<Stop> get filteredStops {
    final activeTypes = transportTypeFilters.entries
        .where((e) => e.value && e.key != "all")
        .map((e) => e.key)
        .toSet();

    // If "all" is selected, show all stops
    if (transportTypeFilters["all"] == true || activeTypes.isEmpty) {
      return searchController.details.value.stops ?? [];
    }

    return (searchController.details.value.stops ?? []).where((stop) {
      final type = stop.routeType?.name.toLowerCase();
      return activeTypes.contains(type);
    }).toList();
  }

  double get distanceInMeters {
    if (selectedUnit.value == "m") {
      return double.parse(selectedDistance.value);
    } else {
      return double.parse(selectedDistance.value * 1000);
    }
  }

  void scrollToStopItem(int stopIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
            index: stopIndex,
            duration: Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            alignment: 0
        );
      }
    });
  }

  Future<void> updateDistance(String distance, String unit) async {
    selectedDistance.value = distance;
    selectedUnit.value = unit;
    await Get.find<search_controller.SearchController>().setStops(
        selectedRouteType.value,
        unit == "m" ? int.parse(distance) : int.parse(distance * 1000)
    );
    await Get.find<MapController>().initialiseNearbyStopMarkers();
  }

  void toggleFilter(ToggleableFilter filter) {
    if (filters.contains(filter)) {
      filters.remove(filter);
    } else {
      filters.add(filter);
    }
  }

  Future<void> toggleTransport(String type) async {
    final isSelected = transportTypeFilters[type]!;
    String toggleTo = isSelected ? "all" : type;
    searchController.resetStopExpanded();
    transportTypeFilters.updateAll((key, value) => key == toggleTo);
    await Get.find<MapController>().initialiseNearbyStopMarkers();
  }

  void resetFilters() {
    selectedDistance.value = "300";
    selectedUnit.value = "m";
    filters.clear();
    transportTypeFilters.value = {
      "all": true,
      "tram": false,
      "bus": false,
      "train": false,
      "vLine": false,
    };
    savedScrollIndex.value = 0;
  }
}
