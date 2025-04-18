import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../controllers/transport_details_controller.dart';
import '../widgets/departure_card.dart';
import '../widgets/transport_widgets.dart';

class TransportDetailsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  final TransportDetailsController transportDetailsController = Get.put(TransportDetailsController());

  TransportDetailsSheet({
    super.key,
    required this.scrollController,});

  @override
  Widget build(BuildContext context) {

    final searchDetails = searchController.details.value;
    final transport = searchDetails.transport!;

    return Obx(() => CustomScrollView(
      controller: scrollController,
      physics: ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 22.0, bottom: 12.0, top: 16.0),
            child: Column(
              children: [
                LocationWidget(textField: transport.stop!.name, textSize: 18, scrollable: true),
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
                        children: [
                          Align(
                              alignment: Alignment.topLeft,
                              child: Text("Towards ${transport.direction!.name}",
                                  style: TextStyle(
                                      fontSize: 16,
                                      height: 1.4
                                  )
                              )
                          ),

                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                            dense: true,
                            title: RouteWidget(route: transport.route!, scrollable: true),
                            trailing: SizedBox(
                              width: 90,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    child: Icon(Icons.info, color: Color(
                                        0xFF4F82FF)),
                                    onTap: () {
                                    },
                                  ),
                                  SizedBox(width: 6),
                                  GestureDetector(
                                    child: Icon(Icons.warning_outlined, color: Color(
                                        0xFFF6833C)),
                                    onTap: () {
                                    },
                                  ),
                                  SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () async {
                                      transportDetailsController.handleSave();
                                      SaveTransportService.renderSnackBar(context, transportDetailsController.isSaved.value);
                                    },
                                    child: FavoriteButton(isSaved: transportDetailsController.isSaved.value),
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
                  children: transportDetailsController.filters.entries.map((MapEntry<String,bool> filter) {
                    return FilterChip(
                        label: Text(filter.key),
                        selected: filter.value,
                        onSelected: (bool selected) {
                          transportDetailsController.setFilters(filter.key);
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
              final departure = transportDetailsController.filteredDepartures[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: DepartureCard(
                  transport: searchDetails.transport!,
                  departure: departure,
                  onDepartureTapped: (departure) {
                    searchController.pushDeparture(departure);
                }),
              );
            },
            childCount: transportDetailsController.filteredDepartures.length,
          )),
        ),
      ],
    ));
  }
}