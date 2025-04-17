import 'package:flutter/cupertino.dart';
import 'package:flutter_project/add_screens/controllers/search_controller.dart' as search_controller;
import 'package:get/get.dart';
import '../../file_service.dart';
import '../../ptv_info_classes/departure_info.dart';

class TransportDetailsController extends GetxController {
  final searchDetails = Get.find<search_controller.SearchController>().details.value;
  final RxBool isSaved = false.obs;
  final RxMap<String, bool> filters = <String, bool>{}.obs;
  final Rx<ScrollController> listController = ScrollController().obs;
  RxList<Departure> filteredDepartures = <Departure>[].obs;

  @override
  void onInit() {
    super.onInit();
    filteredDepartures.assignAll(List.from(searchDetails.transport!.departures!));
  }

  void setFilters(String key) {
    filters[key] = !filters[key]!;
    if (filters['Low Floor'] == true) {
      filteredDepartures.value = filteredDepartures.where(
          (departure) => departure.hasLowFloor
              == filters['Low Floor']).toList();
    }
  }

  // Function to check if transport is saved
  Future<void> checkSaved() async {
    isSaved.value = await isTransportSaved(searchDetails.transport!);
  }

  // Function to save or delete transport
  Future<void> handleSave() async {
    isSaved.value = !isSaved.value;
    if (isSaved.value) {
      await append(searchDetails.transport!);  // Add transport to saved list
      // widget.arguments.callback();
    } else {
      await deleteMatchingTransport(searchDetails.transport!);  // Remove transport from saved list
      // widget.arguments.callback();
    }
  }
}