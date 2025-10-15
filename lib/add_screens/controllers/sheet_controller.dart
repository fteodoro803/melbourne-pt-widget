import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class Sheet {
  String? name;
  dynamic state;

  Sheet({this.name, this.state});

  @override
  String toString() {
    return 'Sheet(name: $name, state: $state)';
  }
}

class SheetController extends GetxController {
  final RxList<Sheet> navigationStack = <Sheet>[].obs;
  final Rx<Sheet> currentSheet = Sheet().obs;
  final RxBool showSheet = false.obs;

  final Rx<Map<String, double>> scrollPositions = Rx<Map<String, double>>({});
  Rx<bool> isSheetExpanded = false.obs;
  double initialSheetSize = 0.4;

  final DraggableScrollableController scrollableController =
      DraggableScrollableController();
  bool _isListenerAdded = false;

  @override
  void onInit() {
    super.onInit();
    print("SheetNavigationController: onInit called");

    // Add listener to the controller
    try {
      scrollableController.addListener(handleSizeChange);
      _isListenerAdded = true;
      print("SheetNavigationController: Listener added successfully");
    } catch (e) {
      print("SheetNavigationController: Error adding listener - $e");
    }
  }

  void handleSizeChange() {
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
            scrollableController.animateTo(size,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          } else {
            print(
                "SheetNavigationController: Controller not attached when trying to animate");
          }
        } catch (e) {
          print("SheetNavigationController: Error animating sheet - $e");
        }
      });
    }
  }

  void pushSheet(String newSheet, dynamic newState) {
    if (scrollableController.isAttached) {
      scrollPositions.value[currentSheet.value.name!] =
          scrollableController.size;
    }
    currentSheet.value = Sheet(name: newSheet, state: newState);
    navigationStack.add(currentSheet.value);
  }

  void popSheet() {
    if (navigationStack.isNotEmpty) {
      final previous = navigationStack.removeLast();
      if (scrollableController.isAttached) {
        scrollPositions.value[currentSheet.value.name!] =
            scrollableController.size;
      }
      if (navigationStack.isNotEmpty) {
        currentSheet.value = navigationStack.last;
      }
      animateToSavedPosition(previous.name!);
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

  @override
  void onClose() {
    print("SheetNavigationController: onClose called");

    try {
      if (_isListenerAdded) {
        scrollableController.removeListener(handleSizeChange);
        _isListenerAdded = false;
      }

      scrollableController.dispose();
      print("SheetNavigationController: Controller successfully disposed");
    } catch (e) {
      print("SheetNavigationController: Error disposing controller - $e");
    }

    super.onClose();
  }
}
