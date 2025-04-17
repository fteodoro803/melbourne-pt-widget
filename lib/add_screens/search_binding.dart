// bindings/search_binding.dart

import 'package:get/get.dart';
import 'controllers/map_controller.dart';
import 'controllers/nearby_stops_controller.dart';
import 'controllers/search_controller.dart' as search_controller;
import 'controllers/sheet_navigator_controller.dart';

class SearchBinding extends Bindings {
  final search_controller.SearchDetails searchDetails;

  SearchBinding({
    required this.searchDetails,
  });

  @override
  void dependencies() {

    // Register dependencies
    Get.lazyPut(() => SheetNavigationController());
    Get.lazyPut(() => search_controller.SearchController());
    Get.lazyPut(() => NearbyStopsController());
    Get.lazyPut(() => MapController());
  }
}
