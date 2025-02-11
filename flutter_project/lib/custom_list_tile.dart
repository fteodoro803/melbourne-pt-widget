import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import 'utilities.dart' as utilities;

class CustomListTile extends StatelessWidget {
  final Transport transport;
  CustomListTile({super.key, required this.transport});

  String? routeTypeName;
  String? routeNumber;
  String? directionName;
  String? stopName;
  String? departure1;
  String? departure2;
  String? departure3;


  @override
  Widget build(BuildContext context) {
  String? routeTypeName = transport.routeType?.name ?? "Null RouteTypeName";
  routeNumber = transport.route?.number ?? "Null RouteNumber";
  directionName = transport.direction?.name ?? "Null DirectionName";
  stopName = transport.stop?.name ?? "Null StopName";
  departure1 = "Null 1st Departure (INITIALISED)";
  departure2 = "Null 2nd Departure (INITIALISED)";
  departure3 = "Null 3rd Departure (INITIALISED)";

  if (transport.departures != null && transport.departures!.length == 3) {
    departure1 = utilities.getTime(transport.departures?[0].estimatedDeparture) ?? utilities.getTime(transport.departures?[0].scheduledDeparture) ?? "Null 1st Departure";
    departure2 = utilities.getTime(transport.departures?[1].estimatedDeparture) ?? utilities.getTime(transport.departures?[1].scheduledDeparture) ?? "Null 2nd Departure";
    departure3 = utilities.getTime(transport.departures?[2].estimatedDeparture) ?? utilities.getTime(transport.departures?[2].scheduledDeparture) ?? "Null 3rd Departure";
  }

  return ListTile(
      isThreeLine: true,
      title: Text("CUSTOM $routeTypeName $routeNumber to $directionName"),
      subtitle: Text("from $stopName\n"
          "$departure1 | $departure2 | $departure3"),
      onTap: () => {},
    );  }
}