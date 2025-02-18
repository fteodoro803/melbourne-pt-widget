import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';

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
    final String routeTypeName = transport.routeType?.name ?? "Null RouteTypeName";
    final String routeNumber = transport.route?.number ?? "Null RouteNumber";
    final String directionName = transport.direction?.name ?? "Null DirectionName";
    final String stopName = transport.stop?.name ?? "Null StopName";

    String departure1;
    String departure2;
    String departure3;

    // Gets the next 3 departures (Prioritises estimated departures to scheduled departures)
    if (transport.departures != null && transport.departures?.length == 3) {
      departure1 = transport.departures?[0].estimatedDepartureTime ?? transport.departures?[0].scheduledDepartureTime ?? "Null 1st Departure";
      departure2 = transport.departures?[1].estimatedDepartureTime ?? transport.departures?[1].scheduledDepartureTime ?? "Null 2nd Departure";
      departure3 = transport.departures?[2].estimatedDepartureTime ?? transport.departures?[2].scheduledDepartureTime ?? "Null 3rd Departure";
    }
    else {
      departure1 = "No Data";
      departure2 = "No Data";
      departure3 = "No Data";
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
        // isThreeLine: true,
        title: Text("$routeTypeName $routeNumber to $directionName"),
        subtitle: Text("from $stopName\n"
            "$departure1 | $departure2 | $departure3"),
        leading: Icon(Icons.tram, size: 50,),
        onTap: onTap,

      ),
  );  }
}