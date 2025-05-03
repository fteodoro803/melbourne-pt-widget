import 'package:flutter/cupertino.dart';
import 'package:flutter_project/add_screens/controllers/search_controller.dart' as search_controller;
import 'package:flutter_project/add_screens/controllers/sheet_controller.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../lib/domain/departure.dart';
import '../lib/ptv_service.dart';

class DepartureDetailsController extends GetxController {

  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  ItemScrollController itemScrollController = ItemScrollController();
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  PtvService ptvService = PtvService();

  RxList<Departure> pattern = <Departure>[].obs;
  RxInt currentStopIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPattern(true);
  }

  Future<void> fetchPattern(bool refreshSheet) async {
    List<Departure> newPattern = await ptvService.fetchPattern(searchController.details.value.trip!, searchController.details.value.departure!);
    pattern.assignAll(newPattern);

    if (refreshSheet) {
      // Find the current stop index
      currentStopIndex.value = pattern.indexWhere(
              (stop) => stop.stopName?.trim().toLowerCase() == searchController.details.value.trip!.stop?.name.trim().toLowerCase()
      );

      // If the stop isn't found, default to 0
      if (currentStopIndex.value == -1) {
        currentStopIndex.value = 0;
      }

      Get.find<SheetNavigationController>().animateSheetTo(0.4);

      // Scroll to the item after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(Duration(milliseconds: 100));


        if (itemScrollController.isAttached) {
          itemScrollController.scrollTo(
            index: currentStopIndex.value,
            duration: Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            alignment: 0,
          );
        }
      });
    }
  }
}