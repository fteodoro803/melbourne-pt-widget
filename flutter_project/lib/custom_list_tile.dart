import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';

class CustomListTile extends StatelessWidget {
  final Transport transport;
  final VoidCallback onTap;
  const CustomListTile({super.key, required this.transport, this.onTap = _emptyFunction});

  // Empty function for default OnTap
  static void _emptyFunction() {}

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

    if (transport.departures != null && transport.departures?.length == 3) {
      departure1 = transport.departures?[0].estimatedDepartureTime ?? transport.departures?[0].scheduledDepartureTime ?? "Null 1st Departure";
      departure2 = transport.departures?[1].estimatedDepartureTime ?? transport.departures?[1].scheduledDepartureTime ?? "Null 2nd Departure";
      departure3 = transport.departures?[2].estimatedDepartureTime ?? transport.departures?[2].scheduledDepartureTime ?? "Null 3rd Departure";
    }
    else {
      departure1 = "Null Departures";
      departure2 = "Null Departures";
      departure3 = "Null Departures";
    }

  return ListTile(
      isThreeLine: true,
      title: Text("$routeTypeName $routeNumber to $directionName"),
      subtitle: Text("from $stopName\n"
          "$departure1 | $departure2 | $departure3"),
      
      leading: Icon(Icons.tram, size: 50,),
      trailing: Icon(Icons.settings, size: 50),
      onTap: onTap,
    );  }
}