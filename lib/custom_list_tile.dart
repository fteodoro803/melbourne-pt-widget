import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/time_utils.dart';

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

  // Function to convert hex string to Color
  Color hexToColor(String hexColor) {
    // Remove the '#' if it's there, just in case
    hexColor = hexColor.replaceAll('#', '');

    // Add the alpha value to the hex code if it's missing
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor; // Default alpha value (FF for full opacity)
    }

    // Convert hex string to integer and create Color object
    return Color(int.parse('0x$hexColor'));
  }

  @override
  Widget build(BuildContext context) {
    final Transport transport = this.transport;   // ~test
    final String routeTypeName = transport.routeType?.name ?? "Null RouteTypeName";
    final String routeNumber = transport.route?.number ?? "Null RouteNumber";
    final String directionName = transport.direction?.name ?? "Null DirectionName";
    final String stopName = transport.stop?.name ?? "Null StopName";
    final String routeColour = transport.route?.colour ?? "Null RouteColour";
    final String routeTextColour = transport.route?.textColour ?? "Null RouteTextColour";

    String departure1;
    String departure2;
    String departure3;

    bool departure1HasLowFloor;
    bool departure2HasLowFloor;
    bool departure3HasLowFloor;

    String departure1Status = TransportUtils.getDepartureStatus(
      transport.departures?[0].estimatedDepartureTime,
      transport.departures?[0].scheduledDepartureTime,
    );
    String departure2Status = TransportUtils.getDepartureStatus(
      transport.departures?[1].estimatedDepartureTime,
      transport.departures?[1].scheduledDepartureTime,
    );
    String departure3Status = TransportUtils.getDepartureStatus(
      transport.departures?[2].estimatedDepartureTime,
      transport.departures?[2].scheduledDepartureTime,
    );

    String minutesUntilNextDeparture;

    // Gets the next 3 departures (Prioritises estimated departures to scheduled departures)
    if (transport.departures != null && transport.departures?.length == 3) {
      departure1 = transport.departures?[0].estimatedDepartureTime ?? transport.departures?[0].scheduledDepartureTime ?? "Null 1st Departure";
      departure2 = transport.departures?[1].estimatedDepartureTime ?? transport.departures?[1].scheduledDepartureTime ?? "Null 2nd Departure";
      departure3 = transport.departures?[2].estimatedDepartureTime ?? transport.departures?[2].scheduledDepartureTime ?? "Null 3rd Departure";

      departure1HasLowFloor = (transport.departures?[0].hasLowFloor ?? false);
      departure2HasLowFloor = (transport.departures?[1].hasLowFloor ?? false);
      departure3HasLowFloor = (transport.departures?[2].hasLowFloor ?? false);

      minutesUntilNextDeparture = (TimeDifference.timeDifference(departure1) != null)
          ? (TimeDifference.timeDifference(departure1)?['minutes'] ?? 0).toString()
          : "No data";
    }
    else {
      departure1 = "No Data";
      departure1HasLowFloor = false;
      departure2 = "No Data";
      departure2HasLowFloor = false;
      departure3 = "No Data";
      departure3HasLowFloor = false;
      minutesUntilNextDeparture = "No data";
    }

    // Set up the minutesUntilNextDepartureText
    String minutesUntilNextDepartureText = "";

    if (minutesUntilNextDeparture == "0") {
      minutesUntilNextDepartureText = "Now";
    } else if (minutesUntilNextDeparture != "No data" && int.parse(minutesUntilNextDeparture) > 60) {
      minutesUntilNextDepartureText = "";  // Display nothing if more than 60 minutes
    } else {
      minutesUntilNextDepartureText = "$minutesUntilNextDeparture min";
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
      // Title and subtitle are structured with Row and Column for formatting
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
                        "$stopName",
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
                      "assets/icons/PTV $routeTypeName Logo.png", // Image for transport type
                      width: 40,
                      height: 40,
                    ),
                    SizedBox(width: 8), // Space between image and text
                    // Route number with bigger text and colored background
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hexToColor(routeColour), // Background color
                        borderRadius: BorderRadius.circular(8), // Rounded corners for background
                      ),
                      child: Text(
                        "$routeNumber", // Route number text
                        style: TextStyle(
                          fontSize: 20, // Bigger text size
                          fontWeight: FontWeight.bold, // Bold text
                          color: hexToColor(routeTextColour), // White text color on blue background
                        ),
                      ),
                    ),
                    SizedBox(width: 8), // Space between route number and direction
                    Text(
                      "to $directionName", // Direction name
                      style: TextStyle(fontSize: 16), // Adjust text size if needed
                      overflow: TextOverflow.ellipsis,  // Apply ellipsis if text overflows
                      maxLines: 1,  // Limit to 1 line
                    ),
                  ],
                ),
                SizedBox(height: 4), // Space between lines

                // Third line: [departure1] | [departure2] | [departure3]
                Row(
                  children: [
                    Text("$departure1",
                      style: TextStyle(
                        color: TransportUtils.getColorForStatus(departure1Status),
                        height: 1.1,
                      ),
                    ),
                    if (departure1HasLowFloor) ...[
                      SizedBox(width: 3),  // Space before icon
                      Image.asset(
                        "assets/icons/Low Floor Icon.png", // Image for low floor
                        width: 14,
                        height: 14,
                      ),
                    ],
                    Text("⎥$departure2",
                      style: TextStyle(
                        color: TransportUtils.getColorForStatus(departure2Status),
                        height: 1.1,
                      ),
                    ),
                    if (departure2HasLowFloor) ...[
                      SizedBox(width: 3),  // Space before icon
                      Image.asset(
                        "assets/icons/Low Floor Icon.png", // Image for low floor
                        width: 14,
                        height: 14,
                      ),
                    ],
                    Text("⎥$departure3",
                      style: TextStyle(
                        color: TransportUtils.getColorForStatus(departure3Status),
                        height: 1.1,
                      ),
                    ),
                    if (departure3HasLowFloor) ...[
                      SizedBox(width: 3),  // Space before icon
                      Image.asset(
                        "assets/icons/Low Floor Icon.png", // Image for low floor
                        width: 14,
                        height: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Container(
            constraints: BoxConstraints(maxWidth: 50),  // Adjust maxWidth to control when wrapping happens
            alignment: Alignment.center,  // Center the text
            child: Column(
              children: [
                // Check if the text is "Now"
                if (minutesUntilNextDepartureText == "Now")
                  Text(
                    minutesUntilNextDepartureText,
                    style: TextStyle(
                      fontSize: 16, // Smaller font size for "Now"
                      fontWeight: FontWeight.w600,
                      color: TransportUtils.getColorForStatus(departure1Status),
                      height: 1.1,
                    ),
                  )
                else ...[
                  // Display first part (first word) bigger for other cases
                  Text(
                    minutesUntilNextDepartureText.split(' ').first,
                    style: TextStyle(
                      fontSize: 20, // Larger font size for the first word
                      fontWeight: FontWeight.w600,
                      color: TransportUtils.getColorForStatus(departure1Status),
                      height: 1.1,
                    ),
                  ),
                  // Display the second part (remaining words)
                  Text(
                    minutesUntilNextDepartureText.split(' ').skip(1).join(' '),
                    style: TextStyle(
                      fontSize: 14, // Smaller font size for the remaining text
                      fontWeight: FontWeight.w600,
                      color: TransportUtils.getColorForStatus(departure1Status),
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
      onTap: onTap,
    ),
  );  }
}