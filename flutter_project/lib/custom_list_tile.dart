import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import 'utilities.dart' as utilities;

class CustomListTile extends StatelessWidget {
  final Transport transport;
  const CustomListTile({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    final String routeTypeName = transport.routeType?.name ?? "Null RouteTypeName";
    final String routeNumber = transport.route?.number ?? "Null RouteNumber";
    final String directionName = transport.direction?.name ?? "Null DirectionName";
    final String stopName = transport.stop?.name ?? "Null StopName";
    final String departure1 = utilities.getTime(transport.departures?[0].estimatedDeparture) ?? utilities.getTime(transport.departures?[0].scheduledDeparture) ?? "Null 1st Departure";
    final String departure2 = utilities.getTime(transport.departures?[1].estimatedDeparture) ?? utilities.getTime(transport.departures?[1].scheduledDeparture) ?? "Null 2nd Departure";
    final String departure3 = utilities.getTime(transport.departures?[2].estimatedDeparture) ?? utilities.getTime(transport.departures?[2].scheduledDeparture) ?? "Null 3rd Departure";

  return ListTile(
      isThreeLine: true,
      title: Text("CUSTOM $routeTypeName $routeNumber to $directionName"),
      subtitle: Text("from $stopName\n"
          "$departure1 | $departure2 | $departure3"),
      onTap: () => {},
    );  }
}