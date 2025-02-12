// Shows a Sample of what the Transit Departure Screen will display
// Also is a confirmation, which leads back to the home page

import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/file_service.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/custom_list_tile.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String _screenName = "ConfirmationScreen";
  DevTools tools = DevTools();

  @override
  void initState() {
    super.initState();
    _initialiseDepartures();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  // Updates UI as a result of Update Departures
  Future<void> _initialiseDepartures() async {
    await widget.arguments.transport.updateDepartures();    // Updates the Transport's departures
    setState(() {});
}

  @override
  Widget build(BuildContext context) {
    final transport = widget.arguments.transport;
    final routeTypeName = transport.routeType?.name ?? "Null RouteType";
    final routeNumber = transport.route?.number ?? "Null RouteNumber";
    final directionName = transport.direction?.name ?? "Null DirectionName";
    final stopName = transport.stop?.name ?? "Null StopName";

    var departure1 = "Null 1st Departure (INITIALISED)";
    var departure2 = "Null 2nd Departure (INITIALISED)";
    var departure3 = "Null 3rd Departure (INITIALISED)";

    if (transport.departures != null && transport.departures!.length == 3) {
      departure1 = transport.departures?[0].estimatedDepartureTime ?? transport.departures?[0].scheduledDepartureTime ?? "Null 1st Departure (SET)";
      departure2 = transport.departures?[1].estimatedDepartureTime ?? transport.departures?[1].scheduledDepartureTime ?? "Null 2nd Departure (SET)";
      departure3 = transport.departures?[2].estimatedDepartureTime ?? transport.departures?[2].scheduledDepartureTime ?? "Null 3rd Departure (SET)";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Confirmation"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListTile(
        isThreeLine: true,
        title: Text("$routeTypeName $routeNumber to $directionName"),
        subtitle: Text("from $stopName\n"
            "$departure1 | $departure2 | $departure3"),
        onTap: () async {
          await append(widget.arguments.transport);
          widget.arguments.callback();    // calls the screen arguments callback function
          Navigator.popUntil(context, ModalRoute.withName("/"));
        },
      ),
    );
  }
}
