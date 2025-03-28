import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/transport_details_screen.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/departures_list.dart';
import '../file_service.dart';

import '../time_utils.dart';
import '../widgets/departure_card.dart';

class StopDetailsSheet extends StatefulWidget {

  final ScreenArguments arguments;
  const StopDetailsSheet({super.key, required this.arguments});

  @override
  State<StopDetailsSheet> createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<StopDetailsSheet> {

  // List<bool> savedList = [];
  List<bool> savedList = [];

  // Function to initialize the savedList
  Future<void> initializeSavedList() async {
    List<bool> tempSavedList = [];

    for (var transport in widget.arguments.searchDetails.directions) {
      // Check if the transport is already saved
      bool isSaved = await isTransportSaved(transport);
      tempSavedList.add(isSaved); // Add true if saved, false if not
    }

    setState(() {
      savedList = tempSavedList; // Set the state with the updated list
    });

    print("SavedList: $savedList");
  }

  @override
  void initState() {
    super.initState();
    // Initialize savedList here, after widget is initialized
    initializeSavedList();

  }

  @override
  Widget build(BuildContext context) {

    if (savedList.isEmpty) {
      return CircularProgressIndicator();
    }

    final transport1 = widget.arguments.searchDetails.directions[0];

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  red: 0,
                  green: 0,
                  blue: 0,
                  alpha: 0.1,
                ),
                spreadRadius: 1,
                blurRadius: 7,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Draggable Scrollable Sheet Handle
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Stop and route details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Stop location
                      Row(
                        children: [
                          Icon(Icons.location_pin, size: 16),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              widget.arguments.searchDetails.stop!.name,
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),

                      // Route details
                      Row(
                        children: [
                          Image.asset(
                            "assets/icons/PTV ${transport1.routeType?.type.name} Logo.png",
                            width: 40,
                            height: 40,
                          ),
                          SizedBox(width: 8),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColourUtils.hexToColour(transport1.route!.colour!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              transport1.routeType!.type.name == "train" || transport1.routeType!.type.name == "vLine" ? widget.arguments.searchDetails.route!.name : widget.arguments.searchDetails.route!.number,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColourUtils.hexToColour(transport1.route!.textColour!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      Column(
                        children: widget.arguments.searchDetails.directions.map((transport) {
                          var departures = transport.departures;
                          var index = widget.arguments.searchDetails.directions.indexOf(transport);
                          bool isSaved = savedList[index];
                          // Now you can safely access savedList[index] based on the transport's index.

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            "Towards ${transport.direction?.name}",
                                            style: TextStyle(fontSize: 18),
                                            // overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      // Spacer(),
                                      GestureDetector(
                                        child: SizedBox(
                                          width: 45,
                                          height: 40,
                                          // decoration: BoxDecoration(
                                          //   // color: savedList[index] ? Color(0xFFEA9CB7) : Colors.grey,
                                          //   borderRadius: BorderRadius.circular(30),
                                          // ),
                                          child: Center(
                                            child: Icon(
                                              savedList[index] ? Icons.star : Icons.star_border,
                                              size: 30,
                                              color: savedList[index] ? Colors.yellow : null,
                                            ),
                                          ),
                                        ),
                                        onTap: () async {
                                          // Toggle the saved status
                                          setState(() {
                                            savedList[index] = !isSaved;
                                          });

                                          // Optionally handle adding/removing the transport
                                          if (savedList[index]) {
                                            await append(transport);  // Add transport to saved list
                                            widget.arguments.callback();
                                          } else {
                                            await deleteMatchingTransport(transport);  // Remove transport from saved list
                                            widget.arguments.callback();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Display departures if they exist
                                if (departures != null && departures.isNotEmpty)
                                  DeparturesList(departuresLength: 2, transport: transport, lowFloorFilter: false, airConditionerFilter: false),

                                // Display a message if no departures
                                if (departures == null || departures.isEmpty)
                                  Card(
                                    margin: const EdgeInsets.all(0.0),
                                    elevation: 0,
                                    child: Text("No departures to show."),
                                  ),
                                GestureDetector(
                                  child: Row(
                                    children: [
                                      SizedBox(width: 16),
                                      Text("See more departures", style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  onTap: () =>
                                  // Navigate to TransportDetailsScreen with transport data
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TransportDetailsScreen(transport: transport, arguments: widget.arguments),
                                      ),
                                    )
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
          ),
        );
      },
    );

  }
}