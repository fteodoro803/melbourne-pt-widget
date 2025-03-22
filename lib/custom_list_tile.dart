import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/time_utils.dart';

import 'add_screens/transport_details_screen.dart';

class CustomListTile extends StatelessWidget {
  final Transport transport;
  final VoidCallback onTap;
  final bool? dismissible;
  final VoidCallback? onDismiss;

  // Constructor
  const CustomListTile({
    super.key,
    required this.transport,
    this.onTap = _emptyFunction,
    this.dismissible,
    this.onDismiss,
  }) : assert(dismissible == false || dismissible == null || (dismissible == true && onDismiss != null), "onDismiss must be provided if dismissible is true");

  // Empty function for default OnTap
  static void _emptyFunction() {}

  // Alert for deleting this stop

  @override
  Widget build(BuildContext context) {
    final Transport transport = this.transport;   // ~test
    final String routeColour = transport.route?.colour ?? "Null RouteColour";
    final String routeTextColour = transport.route?.textColour ?? "Null RouteTextColour";

    String departure1;

    DepartureStatus departure1Status = TransportUtils.getDepartureStatus(
      transport.departures?[0].estimatedDepartureTime,
      transport.departures?[0].scheduledDepartureTime,
    );

    String minutesUntilNextDepartureText;

    // Gets the first departure information
    if (transport.departures != null) {
      departure1 = transport.departures?[0].estimatedDepartureTime ?? transport.departures?[0].scheduledDepartureTime ?? "Null 1st Departure";

      minutesUntilNextDepartureText = TimeUtils.minutesToString(TimeUtils.timeDifference(departure1));
    }
    else {
      departure1 = "No Data";
      minutesUntilNextDepartureText = "";
    }

  // Enables the Widget to be Deleted/Dismissed by Swiping
  return Dismissible(
    key: Key(transport.toString()),
    direction: dismissible == true? DismissDirection.endToStart : DismissDirection.none,    // Dismissible if true
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 30),
      child: Icon(Icons.delete),
    ),
    onDismissed: (_) {
      onDismiss!();
    },

    // Information Tile
    child: ListTile(
      trailing: Container(
        child: Column(
          children: [
            if (minutesUntilNextDepartureText == "Now")
              Text(
                minutesUntilNextDepartureText,
                style: TextStyle(
                  fontSize: 16, // Smaller font size for "Now"
                  fontWeight: FontWeight.w600,
                  color: TransportUtils.getColorForStatus(departure1Status.status),
                  height: 1.1,
                ),
              )
            else ...[
              Text(
                minutesUntilNextDepartureText.split(' ').first,
                style: TextStyle(
                  fontSize: 20, // Larger font size for the first word
                  fontWeight: FontWeight.w600,
                  color: TransportUtils.getColorForStatus(departure1Status.status),
                  height: 1.1,
                ),
              ),
              Text(
                minutesUntilNextDepartureText.split(' ').skip(1).join(' '),
                style: TextStyle(
                  fontSize: 14, // Smaller font size for the remaining text
                  fontWeight: FontWeight.w600,
                  color: TransportUtils.getColorForStatus(departure1Status.status),
                  height: 1.1,
                ),
              ),
            ],
          ],
        ),
      ),
      title: Row(
        children: [
          Expanded(
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
                      "assets/icons/PTV ${transport.routeType?.name} Logo.png",
                      width: 40,
                      height: 40,
                    ),
                    SizedBox(width: 8),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColourUtils.hexToColour(routeColour),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transport.route?.number ?? "No Data",
                        style: TextStyle(
                          fontSize: 20, // Bigger text size
                          fontWeight: FontWeight.bold,
                          color: ColourUtils.hexToColour(routeTextColour),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      transport.direction?.name ?? "No Data",
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
                SizedBox(height: 4),

                Row(
                  children: [
                    if (transport.departures == null || transport.departures!.isEmpty)
                      Text(
                        "No times to show.",
                        style: TextStyle(height: 1.1),
                      )
                    else
                      ...List.generate(
                          transport.departures!.length > 3 ? 3 : transport.departures!.length,
                              (index) {
                            bool hasLowFloor = transport.departures?[index].hasLowFloor ?? false;
                            String departureTime = transport.departures?[index].estimatedDepartureTime ??
                                transport.departures?[index].scheduledDepartureTime ??
                                "No Data";

                            return Row(
                              children: [
                                Text(
                                  departureTime,
                                  style: TextStyle(height: 1.1),
                                ),
                                if (hasLowFloor) ...[
                                  SizedBox(width: 3),
                                  Image.asset(
                                    "assets/icons/Low Floor Icon.png",
                                    width: 14,
                                    height: 14,
                                  ),
                                ],
                                if (index < ((transport.departures!.length > 3 ? 3 : transport.departures!.length) - 1)) ...[
                                  Text(
                                    "⎥",
                                    style: TextStyle(height: 1.1),
                                  ),
                                ],
                              ],
                            );
                          }
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to TransportDetailsScreen with transport data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransportDetailsScreen(transport: transport),
          ),
        );
      },
    ),
  );  }
}