import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/departures_list.dart';
import '../file_service.dart';
import '../ptv_info_classes/departure_info.dart';
import '../transport.dart';
import '../widgets/transport_widgets.dart';

class StopDetailsSheet extends StatefulWidget {

  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Function(Transport) onTransportTapped;
  final Function(Departure) onDepartureTapped;

  const StopDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.onTransportTapped,
    required this.onDepartureTapped
  });

  @override
  State<StopDetailsSheet> createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<StopDetailsSheet> {

  List<bool> savedList = [];

  // Function to add/remove transport from favorites
  Future<void> handleSave(bool isSaved, Transport transport) async {
    if (isSaved) {
      await append(transport);  // Add transport to saved list
      widget.arguments.callback();
    } else {
      await deleteMatchingTransport(transport);  // Remove transport from saved list
      widget.arguments.callback();
    }
  }

  // Function to initialize the savedList
  Future<void> initializeSavedList() async {
    List<bool> tempSavedList = [];

    for (var transport in widget.arguments.searchDetails!.directions) {
      // Check if the transport is already saved
      bool isSaved = await isTransportSaved(transport);
      tempSavedList.add(isSaved); // Add true if saved, false if not
    }

    setState(() {
      savedList = tempSavedList;
    }); // Set the state with the updated list
  }

  @override
  void initState() {
    super.initState();
    initializeSavedList();
  }

  @override
  Widget build(BuildContext context) {

    if (savedList.isEmpty) {
      return CircularProgressIndicator();
    }

    return Column(
      children: [
        // Draggable Scrollable Sheet Handle
        HandleWidget(),

        // Stop and route details
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            controller: widget.scrollController,
            child: Column(
              children: [
                // Stop location
                LocationWidget(textField: widget.arguments.searchDetails!.stop!.name, textSize: 16, scrollable: true),
                SizedBox(height: 4),

                // Route details
                RouteWidget(route: widget.arguments.searchDetails!.route!, scrollable: false,),
                Divider(),

                // Departures for each direction
                Column(
                  children: widget.arguments.searchDetails!.directions.map((transport) {
                    var departures = transport.departures;
                    var index = widget.arguments.searchDetails!.directions.indexOf(transport);
                    bool isSaved = savedList[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(

                              children: [
                                // Direction text
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      "Towards ${transport.direction?.name}",
                                      style: TextStyle(fontSize: 18),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                // Add to Favorites button
                                GestureDetector(
                                  child: FavoriteButton(isSaved: savedList[index]),
                                  onTap: () {
                                    // Toggle the saved status
                                    setState(() {
                                      savedList[index] = !isSaved;
                                    });

                                    handleSave(savedList[index], transport);
                                    SaveTransportService.renderSnackBar(context, savedList[index]);
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Display departures if they exist
                          if (departures != null && departures.isNotEmpty)
                            DeparturesList(departuresLength: 2, transport: transport, lowFloorFilter: false, airConditionerFilter: false,),

                          // Display a message if no departures
                          if (departures == null || departures.isEmpty)
                            Card(
                              margin: const EdgeInsets.all(0.0),
                              elevation: 0,
                              child: Text("No departures to show."),
                            ),

                          // Navigate to Transport Details Sheet
                          GestureDetector(
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Text("See more departures", style: TextStyle(fontSize: 14)),
                              ],
                            ),

                            onTap: () {
                              setState(() {
                                widget.onTransportTapped(transport);
                              });
                            }
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}