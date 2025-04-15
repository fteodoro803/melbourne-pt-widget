import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SheetNavigationController extends GetxController {
  final Rx<String> currentSheet = ''.obs;
  final RxList<String> sheetHistory = <String>[].obs;
  final Rx<Map<String, double>> scrollPositions = Rx<Map<String, double>>({});
  final Rx<bool> isSheetExpanded = false.obs;
  final DraggableScrollableController scrollableController = DraggableScrollableController();

  @override
  void onInit() {
    super.onInit();
    scrollableController.addListener(_handleScrollChange);
  }

  void _handleScrollChange() {
    if (scrollableController.size >= 0.75 && !isSheetExpanded.value) {
      isSheetExpanded.value = true;
      scrollableController.jumpTo(1.0);
    } else if (scrollableController.size < 0.95 && isSheetExpanded.value) {
      isSheetExpanded.value = false;
      scrollableController.jumpTo(0.6);
    }
  }

  void pushSheet(String newSheet) {

    if (currentSheet.value != newSheet) {
      if (scrollableController.isAttached) {
        scrollPositions.value[currentSheet.value] = scrollableController.size;

      }
      sheetHistory.add(currentSheet.value);
      currentSheet.value = newSheet;
      _animateToSavedPosition(newSheet);
    }
  }

  void popSheet() {
    if (sheetHistory.isNotEmpty) {
      final previous = sheetHistory.removeLast();
      if (scrollableController.isAttached) {
        scrollPositions.value[currentSheet.value] = scrollableController.size;
      }
      currentSheet.value = previous;
      _animateToSavedPosition(previous);
    }
  }

  void animateSheetTo(double size, {int delayMs = 100}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (scrollableController.isAttached) {
        scrollableController.animateTo(
            size,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut
        );
      }
    });
  }

  void _animateToSavedPosition(String sheet) {
    final targetSize = scrollPositions.value[sheet] ?? 0.6;
    if (scrollableController.isAttached) {
      scrollableController.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onClose() {
    scrollableController.dispose();
    super.onClose();
  }
}