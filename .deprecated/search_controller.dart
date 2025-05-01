// controllers/search_details_controller.dart

import 'package:flutter_project/add_screens/controllers/sheet_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../lib/domain/stop.dart';
import '../lib/add_screens/utility/search_utils.dart';

// todo: get rid of this controller!

class SearchDetails {

  SearchDetails();
}

class SearchController extends GetxController {
  late Rx<SearchDetails> details = SearchDetails().obs;

  void setDetails(SearchDetails searchDetails) {
    details = searchDetails.obs;
  }


  void resetDetails() => details.value = SearchDetails();
}