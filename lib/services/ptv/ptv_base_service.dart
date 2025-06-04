import 'package:flutter/foundation.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:get/get.dart';
import 'package:flutter_project/database/database.dart' as db;

abstract class PtvBaseService {
  db.AppDatabase database = Get.find<db.AppDatabase>();
  PtvApiService apiService = PtvApiService();

  // Common error handling
  void handleNullResponse(String functionName) {
    if (kDebugMode) {
      print("($functionName) -- Null data response");
    }
  }
}