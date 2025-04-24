import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../controllers/trip_details_controller.dart';
import '../widgets/departure_card.dart';
import '../widgets/trip_widgets.dart';
import '../widgets/trip_details.dart';

class TripDetailsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  final TripDetailsController tripDetailsController = Get.put(TripDetailsController());

  TripDetailsSheet({
    super.key,
    required this.scrollController,});

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      final searchDetails = searchController.details.value;
      final trip = searchDetails.trip!;
      return CustomScrollView(
        controller: scrollController,
        physics: ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 22.0, bottom: 12.0, top: 16.0),
              child: Column(
                children: [
                  LocationWidget(textField: trip.stop!.name, textSize: 18, scrollable: true),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 67,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Color(0xFF717171),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (tripDetailsController.disruptions.isNotEmpty)...[
                                  GestureDetector(
                                    child: Icon(Icons.warning_outlined, color: Color(
                                        0xFFF6833C)),
                                    onTap: () async {
                                      await showModalBottomSheet(
                                        constraints: BoxConstraints(maxHeight: 500),
                                        context: context,
                                        builder: (BuildContext context) {
                                          return TripDetails(
                                            route: searchDetails.route!,
                                            stop: searchDetails.stop!,
                                            disruptions: tripDetailsController.disruptions
                                          );
                                        }
                                      );
                                    },
                                  ),
                                  SizedBox(width: 2),
                                ],
                                Text("Towards ${trip.direction!.name}",
                                    style: TextStyle(
                                        fontSize: 16,
                                        height: 1.4
                                    )
                                ),
                              ],
                            ),

                            ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                              dense: true,
                              title: RouteWidget(route: trip.route!, scrollable: true),
                              trailing: SizedBox(
                                width: 63,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      child: Icon(Icons.info, color: Color(
                                          0xFF4F82FF), size: 27),
                                      onTap: () async {
                                        await showModalBottomSheet(
                                          constraints: BoxConstraints(maxHeight: 500),
                                          context: context,
                                          builder: (BuildContext context) {
                                            return TripDetails(
                                              route: searchDetails.route!,
                                              stop: searchDetails.stop!,
                                              disruptions: tripDetailsController.disruptions
                                            );
                                          }
                                        );
                                      },
                                    ),

                                    SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        tripDetailsController.handleSave();
                                        SaveTripService.renderSnackBar(context, tripDetailsController.isSaved.value);
                                      },
                                      child: Icon(
                                        tripDetailsController.isSaved.value ? Icons.star : Icons.star_border,
                                        size: 30,
                                        color: tripDetailsController.isSaved.value ? Colors.yellow : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 5.0,
                    children: tripDetailsController.filters.entries.map((MapEntry<String,bool> filter) {
                      return FilterChip(
                          label: Text(filter.key),
                          selected: filter.value,
                          onSelected: (bool selected) {
                            tripDetailsController.setFilters(filter.key);
                          }
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 12),
                  Divider(height: 0),
                ],
              ),
            ),
          ),

          // Suburb sticky headers + stops
          SliverStickyHeader(
            header: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  // color: Theme.of(context).colorScheme.surfaceContainerLow,
                  padding: EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upcoming Departures",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 2),
              ],
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final departure = tripDetailsController.filteredDepartures[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: DepartureCard(
                    trip: searchDetails.trip!,
                    departure: departure,
                    onDepartureTapped: (departure) {
                      searchController.pushDeparture(departure);
                  }),
                );
              },
              childCount: tripDetailsController.filteredDepartures.length,
            )),
          ),
        ],
      );
    });
  }
}