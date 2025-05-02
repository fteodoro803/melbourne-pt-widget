import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../controllers/nearby_stops_controller.dart';
import '../controllers/navigation_service.dart';
import '../widgets/nearby_stop_widgets.dart';
import '../widgets/trip_info_widgets.dart';


class NearbyStopsSheet extends StatelessWidget {
  final ScrollController scrollController;
  NearbyStopsController get nearbyController => Get.find<NearbyStopsController>();
  NavigationService get navigationService => Get.find<NavigationService>();

  const NearbyStopsSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {

    // Show header and filters if user scrolls up from list of stops
    nearbyController.itemPositionsListener.itemPositions.addListener(() {
      final firstVisibleItem = nearbyController.itemPositionsListener.itemPositions.value.isNotEmpty
          ? nearbyController.itemPositionsListener.itemPositions.value.first
          : null;

      if (firstVisibleItem != null) {
        if (firstVisibleItem.index == 0 && firstVisibleItem.itemLeadingEdge > 0) {
          scrollController.jumpTo(0);
        }
      }
    });

    return Obx(() => CustomScrollView(
      controller: scrollController,
      physics: ClampingScrollPhysics(),

      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location of stop
                LocationWidget(
                  textField: nearbyController.address.value,
                  textSize: 18,
                  scrollable: true
                ),

                // Search Filters
                SizedBox(height: 8),
                RouteTypeButtons(),
                SizedBox(height: 4),
                Divider(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DistanceFilterChip(),
                      SizedBox(width: 5.0),
                      ToggleFilterChips(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Header item

        if (nearbyController.filteredStops.isNotEmpty)
          SliverFillRemaining(
            hasScrollBody: true,
            fillOverscroll: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ScrollablePositionedList.builder(
                itemScrollController: nearbyController.itemScrollController,
                itemPositionsListener: nearbyController.itemPositionsListener,
                shrinkWrap: true,
                padding: const EdgeInsets.all(0.0),
                itemCount: nearbyController.filteredStops.length,
                itemBuilder: (context, index) {
                  final stopIndex = index;
                  final stop = nearbyController.filteredStops[stopIndex];

                  return Obx(() {
                    final isExpanded = nearbyController.stopExpansionState[stop.id]?.value ?? false;
                    final routes = stop.routes ?? [];
                    final stopName = stop.name;
                    final distance = stop.distance;
                    final routeType = stop.routeType!.name;

                    return Card(
                      color: isExpanded ? Theme
                          .of(context)
                          .colorScheme
                          .surfaceContainerHigh : null,
                      margin: EdgeInsets.only(bottom: isExpanded ? 12 : 4,
                          top: 8,
                          left: 0,
                          right: 0),
                      child: ListTile(
                        visualDensity: VisualDensity(
                            horizontal: -4, vertical: -4),
                        dense: true,
                        contentPadding: EdgeInsets.all(0),
                        // Stop and route details
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              dense: true,
                              visualDensity: VisualDensity(
                                  horizontal: -3, vertical: 0),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 0),
                              title: !isExpanded
                                ? UnexpandedStopWidget(stopName: stopName,
                                  routes: routes, routeType: routeType)
                                : ExpandedStopWidget(
                                  stopName: stopName, distance: distance),
                              leading: Image.asset(
                                "assets/icons/PTV $routeType Logo.png",
                                width: 40,
                                height: 40,
                              ),
                              trailing: Icon(isExpanded
                                  ? Icons.expand_less : Icons.expand_more),
                              onTap: () {
                                if (isExpanded) {
                                  nearbyController.setStopExpanded(
                                      stop.id, false);
                                } else {
                                  nearbyController.setStopExpanded(
                                      stop.id, true);
                                }
                              }
                            ),

                            if (isExpanded)...[
                              Divider(height: 0,),
                              ExpandedStopRoutesWidget(
                                routes: routes,
                                routeType: routeType,
                                stop: stop,
                                onStopTapped: (stop, route) async {
                                  await navigationService.navigateToStop(
                                    stop, route, null);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),
      ],
    ));
  }
}