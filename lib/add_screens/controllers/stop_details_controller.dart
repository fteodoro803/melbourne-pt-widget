import 'package:flutter_project/add_screens/controllers/search_controller.dart' as search_controller;
import 'package:get/get.dart';
import '../../ptv_service.dart';
import '../utility/search_utils.dart';

class StopDetailsController extends GetxController {
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();

  RxList<bool> savedList = <bool>[].obs;
  final isSavedListInitialized = false.obs;
  PtvService ptvService = PtvService();
  SearchUtils searchUtils = SearchUtils();

  // Function to initialize the savedList
  Future<void> initializeSavedList() async {
    await Future.delayed(Duration(milliseconds: 300));
    List<bool> tempSavedList = [];

    for (var trip in searchController.details.value.tripList) {
      // Check if the transport is already saved
      bool isSaved = await ptvService.isTripSaved(trip);
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
    for (var trip in searchController.details.value.tripList) {
      int index = searchController.details.value.tripList.indexOf(trip);
      bool wasSaved = savedList[index];
      bool isNowSaved = tempSavedList[index];
      if (wasSaved != isNowSaved) {
        await searchUtils.handleSave(trip);
      }
    }
    savedList.assignAll(tempSavedList);
  }
}