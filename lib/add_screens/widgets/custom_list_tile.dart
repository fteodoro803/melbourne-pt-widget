import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import 'transport_widgets.dart';

import '../utility/time_utils.dart';

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
    final Transport transport = this.transport;

    final departure = transport.departures != null && transport.departures!.isNotEmpty ? transport.departures![0] : null;
    final String estimatedDepartureTime = departure?.estimatedDepartureTime ?? departure?.scheduledDepartureTime ?? "No Data";
    final DepartureStatus status = TransportUtils.getDepartureStatus(
      departure?.scheduledDepartureTime,
      departure?.estimatedDepartureTime,
    );
    Map<String, int>? timeToDeparture = TimeUtils.timeDifference(estimatedDepartureTime);

    String? timeString;

    if (timeToDeparture?['days'] == 0 && timeToDeparture?['hours'] == 0) {
      if (timeToDeparture?['minutes'] == 0) {
        timeString = "Now";
      }
      else if (timeToDeparture!['minutes']! > 0){
        timeString = "${timeToDeparture['minutes']!} min";
      }
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
      contentPadding: EdgeInsets.only(left: 12, right: 16, top: 4),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LocationWidget above the vertical line
          LocationWidget(textField: transport.stop!.name, textSize: 16, scrollable: false),
          SizedBox(height: 2),
          RouteWidget(route: transport.route!, direction: transport.direction, scrollable: false,),

          // Row for the vertical line and the rest of the widgets
          if (transport.departures != null)
            ListTile(
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              leading: Icon(Icons.access_time_filled),
              title: DeparturesStringWidget(departures: transport.departures),
              trailing: timeString != null
                ? Container(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  decoration: BoxDecoration(
                    color: ColourUtils.getColorForStatus(status.status),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    timeString,
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 15
                    ),
                  ),
                )
                : null,
            ),
        ],
      ),
      onTap: onTap,
    ),
  );  }
}

