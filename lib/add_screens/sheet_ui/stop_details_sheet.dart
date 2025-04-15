import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../controllers/stop_details_controller.dart';
import '../widgets/departure_card.dart';
import '../widgets/save_transport_sheet.dart';
import '../widgets/transport_widgets.dart';

class StopDetailsSheet extends StatelessWidget {
  final search_controller.SearchController searchController = Get.find<search_controller.SearchController>();
  final StopDetailsController stopDetailsController = Get.put(StopDetailsController());
  final ScrollController scrollController;

  StopDetailsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      if (!stopDetailsController.isSavedListInitialized.value) {
        return Center(child: CircularProgressIndicator());
      }

      final searchDetails = searchController.details.value;
      final transportsList = searchDetails.transportList!;
      final savedList = stopDetailsController.savedList;

      return ListView(
        padding: EdgeInsets.zero,
        controller: scrollController,
        physics: ClampingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationWidget(textField: searchDetails.stop!.name,
                    textSize: 18,
                    scrollable: true),

                // Stop location
                ListTile(
                  contentPadding: EdgeInsets.all(0),
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  title: Row(
                    children: [
                      SizedBox(width: 8),
                      Container(
                        width: 4,

                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Color(0xFF717171),
                        ),
                      ),
                      SizedBox(width: 10),
                      RouteWidget(
                        route: searchDetails.route!, scrollable: false,),
                    ],
                  ),
                  trailing: GestureDetector(
                    child: FavoriteButton(isSaved: savedList.contains(true)),
                    onTap: () async {
                      await showModalBottomSheet(
                          constraints: BoxConstraints(maxHeight: 320),
                          context: context,
                          builder: (BuildContext context) {
                            return SaveTransportSheet(
                              savedList: savedList,
                              searchDetails: searchDetails,
                              onConfirmPressed: stopDetailsController
                                  .onConfirmPressed,
                            );
                          }
                      );
                    },
                  ),
                ),
                Divider(),

                // Departures for each direction
                Column(
                  children: transportsList.map((transport) {
                    var departures = transport.departures;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            visualDensity: VisualDensity(
                                horizontal: -4, vertical: -4),
                            dense: true,
                            contentPadding: EdgeInsets.all(0),
                            title: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                "Towards ${transport.direction?.name}",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 100,
                              child: GestureDetector(
                                child: Row(
                                  children: [
                                    SizedBox(width: 18),
                                    Text("See all",
                                        style: TextStyle(fontSize: 16,)),
                                    Icon(Icons.keyboard_arrow_right),
                                  ],
                                ),
                                onTap: () =>
                                    searchController.pushTransport(transport),
                              ),
                            ),
                          ),

                          // Display departures if they exist
                          if (departures != null && departures.isNotEmpty)

                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(0.0),
                              itemCount: departures.length > 2 ? 2 : departures
                                  .length,
                              itemBuilder: (context, index) {
                                final departure = departures[index];
                                return DepartureCard(
                                    transport: transport,
                                    departure: departure,
                                    onDepartureTapped: (departure) {
                                      searchController.setTransport(transport);
                                      searchController.pushDeparture(departure);
                                    });
                              },
                            ),

                          // Display a message if no departures
                          if (departures == null || departures.isEmpty)
                            Card(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              elevation: 1,
                              child: Text("No departures to show."),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}