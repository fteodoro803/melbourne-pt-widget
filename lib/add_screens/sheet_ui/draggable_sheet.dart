import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';

import '../controllers/sheet_navigator_controller.dart';
import '../widgets/screen_widgets.dart';

class SheetNavigatorWidget extends GetView<SheetNavigationController> {
  final Map<String, Widget Function(BuildContext, ScrollController)> sheets;
  final String initialSheet;

  const SheetNavigatorWidget({
    Key? key,
    required this.sheets,
    required this.initialSheet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller with initial sheet
    controller.currentSheet.value = initialSheet;

    return DraggableScrollableSheet(
      controller: controller.scrollableController,
      initialChildSize: 0.6,
      minChildSize: 0.15,
      maxChildSize: 1.0,
      expand: true,
      shouldCloseOnMinExtent: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Obx(() => controller.isSheetExpanded.value
              ? Column(
            children: [
              const SizedBox(height: 50),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => controller.popSheet(),
                  ),
                  Expanded(
                    child: Text(
                      controller.currentSheet.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_pin),
                    onPressed: () => controller.scrollableController.jumpTo(0.6),
                  ),
                ],
              ),
              const Divider(),
              Expanded(child: sheets[controller.currentSheet.value]!(context, scrollController)),
            ],
          )
              : Column(
              children: [
                HandleWidget(),
                Expanded(child: sheets[controller.currentSheet.value]!(context, scrollController))
              ]
          )),
        );
      },
    );
  }
}