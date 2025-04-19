import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SheetNavigationController extends GetxController {
  final Rx<String> currentSheet = ''.obs;
  final RxList<String> sheetHistory = <String>[].obs;
  final Rx<Map<String, double>> scrollPositions = Rx<Map<String, double>>({});
  Rx<bool> isSheetExpanded = false.obs;
  double initialSheetSize = 0.4;

  // Don't use late - initialize immediately
  final DraggableScrollableController scrollableController = DraggableScrollableController();
  bool _isListenerAdded = false;

  @override
  void onInit() {
    super.onInit();
    print("SheetNavigationController: onInit called");

    // Add listener to the controller
    try {
      scrollableController.addListener(handleScrollChange);
      _isListenerAdded = true;
      print("SheetNavigationController: Listener added successfully");
    } catch (e) {
      print("SheetNavigationController: Error adding listener - $e");
    }
  }

  void setInitialSheetSize(double size) {
    initialSheetSize = size;
  }

  void handleScrollChange() {
    try {
      if (scrollableController.size >= 0.75 && !isSheetExpanded.value) {
        isSheetExpanded.value = true;
        scrollableController.jumpTo(1.0);
      } else if (scrollableController.size < 0.95 && isSheetExpanded.value) {
        isSheetExpanded.value = false;
        scrollableController.jumpTo(0.6);
      }
    } catch (e) {
      print("Error in handleScrollChange: $e");
    }
  }

  // Safer version of animateTo
  void animateSheetTo(double size, {int delayMs = 100}) {
    if (scrollableController.isAttached && size != scrollableController.size) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        try {
          if (scrollableController.isAttached) {
            scrollableController.animateTo(
                size,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut
            );
          } else {
            print("SheetNavigationController: Controller not attached when trying to animate");
          }
        } catch (e) {
          print("SheetNavigationController: Error animating sheet - $e");
        }
      });
    }
  }

  @override
  void onClose() {
    print("SheetNavigationController: onClose called");

    try {
      if (_isListenerAdded) {
        scrollableController.removeListener(handleScrollChange);
        _isListenerAdded = false;
      }

      scrollableController.dispose();
      print("SheetNavigationController: Controller successfully disposed");
    } catch (e) {
      print("SheetNavigationController: Error disposing controller - $e");
    }

    super.onClose();
  }

  void pushSheet(String newSheet) {

    if (currentSheet.value != newSheet) {
      if (scrollableController.isAttached) {
        scrollPositions.value[currentSheet.value] = scrollableController.size;

      }
      sheetHistory.add(currentSheet.value);
      currentSheet.value = newSheet;
      // _animateToSavedPosition(newSheet);
    }
  }

  void popSheet() {
    if (sheetHistory.isNotEmpty) {
      final previous = sheetHistory.removeLast();
      if (scrollableController.isAttached) {
        scrollPositions.value[currentSheet.value] = scrollableController.size;
      }
      currentSheet.value = previous;
      animateToSavedPosition(previous);
    }
  }

  void animateToSavedPosition(String sheet) {
    final targetSize = scrollPositions.value[sheet] ?? 0.6;
    if (scrollableController.isAttached) {
      scrollableController.animateTo(
        targetSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}