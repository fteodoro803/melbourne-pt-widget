// controllers/nearby_stops_controller.dart

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_project/domain/stop.dart';
import '../utility/search_utils.dart';
import 'map_controller.dart';

enum ToggleableFilter {
  lowFloor(name: "Low Floor"),
  shelter(name: "Shelter");

  final String name;
  const ToggleableFilter({required this.name});
}

class NearbyStopsController extends GetxController {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  final RxString selectedDistance = "300".obs;
  final RxString selectedUnit = "m".obs;
  final RxSet<ToggleableFilter> filters = <ToggleableFilter>{}.obs;
  final RxString selectedRouteType = "all".obs;
  final RxList<Stop> stops = <Stop>[].obs;
  final RxString address = "".obs;
  final RxInt savedScrollIndex = 0.obs;
  final RxMap<int, RxBool> stopExpansionState = <int, RxBool>{}.obs;

  final SearchUtils searchUtils = SearchUtils();

  final RxMap<String, bool> routeTypeFilters = {
    "all": true,
    "tram": false,
    "bus": false,
    "train": false,
    "vLine": false,
  }.obs;

  /// Returns subset of nearby stops that match current filters
  List<Stop> get filteredStops {
    final activeTypes = routeTypeFilters.entries
        .where((e) => e.value && e.key != "all")
        .map((e) => e.key)
        .toSet();

    if (routeTypeFilters["all"] == true || activeTypes.isEmpty) {
      return stops;
    }

    return stops.where((stop) {
      final type = stop.routeType?.name.toLowerCase();
      return activeTypes.contains(type);
    }).toList();
  }

  /// Converts distance string to a double representing meters
  double get distanceInMeters {
    if (selectedUnit.value == "m") {
      return double.parse(selectedDistance.value);
    } else {
      return double.parse(selectedDistance.value * 1000);
    }
  }

  void setAddress(String newAddress) => address.value = newAddress;

  /// Sets new stops list & initializes expansion states
  Future<void> setStops(String routeType, int distance) async {
    List<Stop> uniqueStops = await searchUtils.getUniqueStops(Get.find<MapController>().markerPos!, routeType, distance);

    stops.value = uniqueStops.obs;

    resetStopExpanded();
  }

  /// Set all stops as unexpanded
  void resetStopExpanded() {
    for (var stop in stops) {
      stopExpansionState[stop.id] = false.obs;
    }
  }

  /// Expand a given stop
  void setStopExpanded(int stopId, bool expand) {
    if (stopExpansionState.containsKey(stopId)) {
      stopExpansionState[stopId]!.value = expand;
    } else {
      stopExpansionState[stopId] = expand.obs;
    }
  }

  /// Automatically scroll to a given stop
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

  /// Handles change in distance filter
  Future<void> updateDistance(String distance, String unit) async {
    selectedDistance.value = distance;
    selectedUnit.value = unit;
    await setStops(selectedRouteType.value,
        unit == "m" ? int.parse(distance) : int.parse(distance * 1000)
    );
    if (Get.find<MapController>().isNearbyStopsButtonToggled.value) {
      Get.find<MapController>().initialiseNearbyStopMarkers();
      Get.find<MapController>().showNearbyStopMarkers();
    }
  }

  /// Updates value of toggleable filters
  void toggleFilter(ToggleableFilter filter) {
    if (filters.contains(filter)) {
      filters.remove(filter);
    } else {
      filters.add(filter);
    }
  }

  /// Handles change in routeType filter
  Future<void> toggleRouteType(String type) async {
    final isSelected = routeTypeFilters[type]!;
    String toggleTo = isSelected ? "all" : type;
    resetStopExpanded();
    routeTypeFilters.updateAll((key, value) => key == toggleTo);
    if (Get.find<MapController>().isNearbyStopsButtonToggled.value) {
      Get.find<MapController>().initialiseNearbyStopMarkers();
      Get.find<MapController>().showNearbyStopMarkers();
    }
  }

  /// Resets all filters
  void resetFilters() {
    selectedDistance.value = "300";
    selectedUnit.value = "m";
    filters.clear();
    routeTypeFilters.value = {
      "all": true,
      "tram": false,
      "bus": false,
      "train": false,
      "vLine": false,
    };
    savedScrollIndex.value = 0;
  }
}
