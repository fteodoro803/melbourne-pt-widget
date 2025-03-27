import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';
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

  @override
  Widget build(BuildContext context) {

    final transport1 = widget.arguments.searchDetails.directions[0];
    final transport2 = widget.arguments.searchDetails.directions[1];

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
                              widget.arguments.searchDetails.route!.number,
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
                      ListTile(
                        title: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Text(
                                      "Towards ${transport1.direction?.name}",
                                      style: TextStyle(fontSize: 16),
                                  ),
                                  Spacer(),
                                  // ADD BUTTON HERE
                                ],
                              ),
                            ),
                            DepartureCard(departure: widget.arguments.searchDetails.directions[0].departures![0], transport: transport1),
                            DepartureCard(departure: widget.arguments.searchDetails.directions[0].departures![1], transport: transport1),
                            if (widget.arguments.searchDetails.directions[0].departures == null)
                              Card(color: Colors.white,
                                  margin: const EdgeInsets.all(0.0),
                                  elevation: 0,
                                  child: Text("No departures to show.")),
                          ],
                        ),
                        onTap: () async {
                          await append(transport1);
                          widget.arguments.callback(); // calls the screen arguments callback function
                        },
                      ),

                      SizedBox(height: 12),

                      ListTile(
                        title: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Towards ${transport2.direction?.name}",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            // if (widget.arguments.searchDetails.directions[1].departures?[0] != null)
                            DepartureCard(departure: widget.arguments.searchDetails.directions[1].departures![0], transport: transport2),
                              // if (widget.arguments.searchDetails.directions[1].departures!.length >= 2)
                            DepartureCard(departure: widget.arguments.searchDetails.directions[1].departures![1], transport: transport2),
                            if (widget.arguments.searchDetails.directions[1].departures == null)
                              Card(color: Colors.white,
                                  margin: const EdgeInsets.all(0.0),
                                  elevation: 0,
                                  child: Text("No departures to show.")),
                          ],
                        ),
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