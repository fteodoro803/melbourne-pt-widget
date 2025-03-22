import 'dart:async';

import 'package:flutter/material.dart';
import '../departure_service.dart';
import '../ptv_info_classes/departure_info.dart';
import '../time_utils.dart';
import '../transport.dart';

class TransportDetailsScreen extends StatefulWidget {
  final Transport transport;

  TransportDetailsScreen({required this.transport});

  @override
  _TransportDetailsScreenState createState() => _TransportDetailsScreenState();
}

class _TransportDetailsScreenState extends State<TransportDetailsScreen> {
  late Transport transport;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    transport = widget.transport;

    // Update departures when the screen is initialized
    updateDepartures();

    // Set up a timer to update departures every 30 seconds (30,000 milliseconds)
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      updateDepartures();
    });
  }

  // Update Departures
  Future<void> updateDepartures() async {
    String? routeType = transport.routeType?.type;
    String? stopId = transport.stop?.id;
    String? directionId = transport.direction?.id;
    String? routeId = transport.route?.id;

    // Early exit if any of the prerequisites are null
    if (routeType == null || stopId == null || directionId == null || routeId == null) {
      return;
    }

    // Gets Departures and saves to instance
    DepartureService departureService = DepartureService();
    List<Departure>? updatedDepartures = await departureService.fetchDepartures(
        routeType, stopId, directionId, routeId
    );

    setState(() {
      transport.departures = updatedDepartures;
    });
    }

  @override
  void dispose() {
    // Cancel the timer when the screen is disposed
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Transport Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First line: [location_pin] [stopName]
            Row(
              children: [
                Icon(Icons.location_pin, size: 16), // Icon for location
                SizedBox(width: 3), // Space between icon and text
                Flexible(
                  child: Text(
                    transport.stop?.name ?? "No Data",
                    style: TextStyle(fontSize: 16), // Adjust stopName font size
                    overflow: TextOverflow.ellipsis,  // Apply ellipsis if text overflows
                    maxLines: 1,  // Limit to 1 line
                  ),
                ),
              ],
            ),
            SizedBox(height: 4), // Space between lines

            // Second line: [transportTypeImage] [routeNumber] to [directionName]
            Row(
              children: [
                Image.asset(
                  "assets/icons/PTV ${transport.routeType?.name} Logo.png", // Image for transport type
                  width: 40,
                  height: 40,
                ),
                SizedBox(width: 8), // Space between image and text
                // Route number with bigger text and colored background
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColourUtils.hexToColour(transport.route!.colour ?? "Null RouteColour"), // Background color
                    borderRadius: BorderRadius.circular(8), // Rounded corners for background
                  ),
                  child: Text(
                    transport.route?.number ?? "No Data", // Route number text
                    style: TextStyle(
                      fontSize: 20, // Bigger text size
                      fontWeight: FontWeight.bold, // Bold text
                      color: ColourUtils.hexToColour(transport.route?.textColour ?? "Null RouteTextColour"), // White text color on blue background
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4), // Space between lines
            Divider(),

            Text("Upcoming Departures"),
            Expanded(
              child: ListView.builder(
                itemCount: transport.departures!.length > 50 ? 50 : transport.departures!.length,  // Only show next 50 departures
                itemBuilder: (context, index) {
                  final departure = transport.departures?[index];
                  final String departureTime = departure?.estimatedDepartureTime ?? departure?.scheduledDepartureTime ?? "No Data";
                  final DepartureStatus status = TransportUtils.getDepartureStatus(
                    departure?.estimatedDepartureTime,
                    departure?.scheduledDepartureTime,
                  );
                  final bool hasLowFloor = departure?.hasLowFloor ?? false;
                  String minutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(departureTime));

                  return ListTile(
                    title: Text("${transport.direction?.name}"),
                    subtitle: Row(
                      children: [
                        Text(
                          "${status.status} ",
                          style: TextStyle(
                            color: TransportUtils.getColorForStatus(status.status),
                          ),
                        ),
                        Text(
                          status.timeDifference != null ? "${status.timeDifference} min • $departureTime" : "• $departureTime",
                          style: TextStyle(
                            color: TransportUtils.getColorForStatus(status.status),
                          ),
                        ),
                        // Text(
                        //   "$departureTime",
                        //   style: TextStyle(
                        //     color: TransportUtils.getColorForStatus(status.status),
                        //     // decoration: (status.status == "Delayed") ? TextDecoration.lineThrough : TextDecoration.none,
                        //     // decorationColor: TransportUtils.getColorForStatus(status.status),
                        //   ),
                        // ),
                        if (hasLowFloor) ...[
                          SizedBox(width: 4),  // Space before icon
                          Image.asset(
                            "assets/icons/Low Floor Icon.png", // Image for low floor
                            width: 14,
                            height: 14,
                          ),
                        ],
                      ],
                    ),
                    trailing:
                      Text(
                        minutesUntilNextDepartureString,
                        style: TextStyle(
                          fontSize: 15,
                          color: TransportUtils.getColorForStatus(status.status),
                        ),
                      ),
                    onTap: () {
                      print("Tapped on departure at $departureTime");
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}