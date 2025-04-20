import 'package:flutter_project/add_screens/controllers/search_controller.dart' as search_controller;
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../ptv_service.dart';

class StopDetailsController extends GetxController {
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();

  RxList<bool> savedList = <bool>[].obs;
  final isSavedListInitialized = false.obs;
  PtvService ptvService = PtvService();

  // Function to initialize the savedList
  Future<void> initializeSavedList() async {
    await Future.delayed(Duration(milliseconds: 300));
    List<bool> tempSavedList = [];

    for (var transport in searchController.details.value.transportList!) {
      // Check if the transport is already saved
      bool isSaved = await ptvService.isTripSaved(transport);
      tempSavedList.add(isSaved);
    }

    savedList.assignAll(tempSavedList);
    isSavedListInitialized.value = true;
  }

  @override
  void onInit() {
    super.onInit();
    initializeSavedList();
  }

  Future<void> onConfirmPressed(List<bool> tempSavedList) async {
    for (var transport in searchController.details.value.transportList!) {
      int index = searchController.details.value.transportList!.indexOf(transport);
      bool wasSaved = savedList[index];
      bool isNowSaved = tempSavedList[index];
      if (wasSaved != isNowSaved) {
        if (!wasSaved) {
          await ptvService.saveTrip(transport);
          // widget.arguments.callback();
        }
        else {
          await ptvService.deleteTrip(transport.uniqueID!);
          // widget.arguments.callback();
        }
      }
    }
    savedList.assignAll(tempSavedList);
  }
}