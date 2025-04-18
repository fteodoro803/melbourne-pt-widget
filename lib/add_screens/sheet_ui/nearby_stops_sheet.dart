import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../controllers/nearby_stops_controller.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../widgets/distance_filter.dart';
import '../widgets/screen_widgets.dart' as screen_widgets;
import '../widgets/get_widgets.dart';


class NearbyStopsSheet extends StatelessWidget {
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  final NearbyStopsController nearbyController = Get.find<NearbyStopsController>();
  final ScrollController scrollController;

  NearbyStopsSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {

    // Add listener to the ItemPositionsListener
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
                LocationWidget(
                    textField: searchController.details.value.address ?? "Address not found",
                    textSize: 18,
                    scrollable: true
                ),
                SizedBox(height: 8),
                Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: nearbyController.transportTypeFilters.keys.map((transportType) {
                    final isSelected = nearbyController.transportTypeFilters[transportType] ?? false;
                    return screen_widgets.TransportToggleButton(
                      isSelected: isSelected,
                      transportType: transportType,
                      handleTransportToggle: (transportType) {
                        nearbyController.toggleTransport(transportType);
                      }
                    );
                  }).toList(),
                ),
                SizedBox(height: 4),
                Divider(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: Icon(Icons.keyboard_arrow_down_sharp),
                        label: Text('Within ${nearbyController.selectedDistance.value}${nearbyController.selectedUnit.value}'),
                        onPressed: () async {
                          await showModalBottomSheet(
                            constraints: BoxConstraints(maxHeight: 500),
                            context: context,
                            builder: (BuildContext context) {
                              return DistanceFilterSheet(
                                selectedDistance: nearbyController.selectedDistance.value,
                                selectedUnit: nearbyController.selectedUnit.value,
                                onConfirmPressed: (distance, unit) {
                                  nearbyController.updateDistance(distance, unit);
                                }
                              );
                            });
                        },

                      ),
                      SizedBox(width: 5.0),
                      Wrap(
                        spacing: 5.0,
                        children:
                        ToggleableFilter.values.map((ToggleableFilter result) {
                          return FilterChip(
                              label: Text(result.name),
                              selected: nearbyController.filters.contains(result),
                              onSelected: (bool selected) {
                                if (selected) {
                                  nearbyController.filters.add(result);
                                } else {
                                  nearbyController.filters.remove(result);
                                }
                              }
                          );
                        }).toList(),
                      ),
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
                  // Stop items
                  final stopIndex = index;
                  final stop = nearbyController.filteredStops[stopIndex];

                  return Obx(() {
                    final isExpanded = searchController.stopExpansionState[stop.id]?.value ?? false;
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
                                    routes: routes,
                                    routeType: routeType)
                                    : ExpandedStopWidget(
                                    stopName: stopName, distance: distance),
                                leading: Image.asset(
                                  "assets/icons/PTV $routeType Logo.png",
                                  width: 40,
                                  height: 40,
                                ),
                                trailing: Icon(
                                    isExpanded ? Icons.expand_less : Icons
                                        .expand_more),
                                onTap: () {
                                  if (isExpanded) {
                                    searchController.setStopExpanded(
                                        stop.id, false);
                                  } else {
                                    searchController.setStopExpanded(
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
                                  await searchController.setRoute(route);
                                  await searchController.pushStop(stop);
                                  // sheetNavigator.pushSheet("Stop Details");
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