import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';

class CustomListTile extends StatelessWidget {
  final Transport transport;
  const CustomListTile({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    final String routeTypeName = transport.routeType?.name ?? "Null RouteTypeName";
    final String routeNumber = transport.route?.number ?? "Null RouteNumber";
    final String directionName = transport.direction?.name ?? "Null DirectionName";
    final String stopName = transport.stop?.name ?? "Null StopName";
    final String departure1 = transport.departures?[0].estimatedDepartureTime ?? transport.departures?[0].scheduledDepartureTime ?? "Null 1st Departure";
    final String departure2 = transport.departures?[1].estimatedDepartureTime ?? transport.departures?[1].scheduledDepartureTime ?? "Null 2nd Departure";
    final String departure3 = transport.departures?[2].estimatedDepartureTime ?? transport.departures?[2].scheduledDepartureTime ?? "Null 3rd Departure";

  return ListTile(
      isThreeLine: true,
      title: Text("$routeTypeName $routeNumber to $directionName"),
      subtitle: Text("from $stopName\n"
          "$departure1 | $departure2 | $departure3"),
      
      leading: Icon(Icons.tram, size: 50,),
      trailing: Icon(Icons.settings, size: 50),
      
      onTap: () => {},
    );  }
}