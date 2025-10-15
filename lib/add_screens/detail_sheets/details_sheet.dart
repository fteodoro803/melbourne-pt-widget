import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_service.dart';
import '../controllers/sheet_controller.dart';
import '../widgets/buttons.dart';

class SheetNavigatorWidget extends StatelessWidget {
  final Map<String, Widget Function(BuildContext, ScrollController)> sheets;
  final SheetController controller;
  NavigationService get navigationService => Get.find<NavigationService>();

  const SheetNavigatorWidget({
    super.key,
    required this.sheets,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller.scrollableController,
      initialChildSize: controller.initialSheetSize,
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
                          onPressed: navigationService.handleBackNavigation,
                        ),
                        Expanded(
                          child: Text(
                            controller.currentSheet.value.name!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_pin),
                          onPressed: () =>
                              controller.scrollableController.jumpTo(0.6),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                        child: sheets[controller.currentSheet.value.name]!(
                            context, scrollController)),
                  ],
                )
              : Column(children: [
                  HandleWidget(),
                  Expanded(
                      child: sheets[controller.currentSheet.value.name]!(
                          context, scrollController))
                ])),
        );
      },
    );
  }
}
