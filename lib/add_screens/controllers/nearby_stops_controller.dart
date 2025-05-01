// controllers/nearby_stops_controller.dart

import 'package:flutter/cupertino.dart';
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
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  final RxString selectedDistance = "300".obs;
  final RxString selectedUnit = "m".obs;
  final RxSet<ToggleableFilter> filters = <ToggleableFilter>{}.obs;
  final RxString selectedRouteType = "all".obs;
  final RxList<Stop> stops = <Stop>[].obs;
  RxString address = "".obs;

  final RxInt savedScrollIndex = 0.obs;
  final RxMap<int, RxBool> stopExpansionState = <int, RxBool>{}.obs;

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
      return stops;
    }

    return stops.where((stop) {
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

  void setAddress(String newAddress) {
    address = newAddress.obs;
  }

  /// Sets new stops list & initializes expansion states
  Future<void> setStops(String routeType, int distance) async {
    List<Stop> uniqueStops = await searchUtils.getUniqueStops(Get.find<MapController>().markerPos!, routeType, distance);

    stops.value = uniqueStops.obs;

    resetStopExpanded();
  }

  void resetStopExpanded() {
    for (var stop in stops) {
      stopExpansionState[stop.id] = false.obs;
    }
  }

  void setStopExpanded(int stopId, bool expand) {
    if (stopExpansionState.containsKey(stopId)) {
      stopExpansionState[stopId]!.value = expand;
    } else {
      stopExpansionState[stopId] = expand.obs;
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
    await setStops(selectedRouteType.value,
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
    resetStopExpanded();
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
