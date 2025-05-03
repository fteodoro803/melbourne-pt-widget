// bindings/search_binding.dart

import 'package:get/get.dart';
import 'controllers/map_controller.dart';
import 'controllers/navigation_service.dart';
import 'controllers/nearby_stops_controller.dart';
import 'controllers/sheet_controller.dart';

class SearchBinding extends Bindings {

  SearchBinding();

  @override
  void dependencies() {

    // Register dependencies
    Get.lazyPut(() => SheetController());
    Get.lazyPut(() => NavigationService());
    Get.lazyPut(() => NearbyStopsController());
    Get.lazyPut(() => MapController());
  }
}
