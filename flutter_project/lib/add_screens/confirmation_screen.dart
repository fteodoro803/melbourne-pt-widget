// Shows a Sample of what the Transit Departure Screen will display
// Also is a confirmation, which leads back to the home page

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/departure_service.dart';

import 'package:flutter_project/custom_list_tile.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key, required this.transport});

  // Stores user Transport details
  final Transport transport;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String _screenName = "ConfirmationScreen";

  @override
  void initState() {
    super.initState();
    fetchDepartures();

    // Debug Printing
    if (kDebugMode) {
      print("Screen: $_screenName");
    }
  }

  // NEW FETCH DEPARTURES
  Future<void> fetchDepartures() async {
    String routeType = widget.transport.routeType!.type;
    String stopId = widget.transport.stop!.id;
    String directionId = widget.transport.direction!.id;
    String routeId = widget.transport.route!.id;

    // Gets Departures
    DepartureService departureService = DepartureService();
    List<Departure> fetchedDepartures = await departureService.fetchDepartures(
        routeType, stopId, directionId, routeId);

    setState(() {
      widget.transport.departures = fetchedDepartures;
    });
  }

  // Returns the Time from a DateTime variable
  String? getTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    // Adds a '0' to the left, if Single digit time (ex: 7 becomes 07)
    String hour = dateTime.hour.toString().padLeft(2, "0");
    String minute = dateTime.minute.toString().padLeft(2, "0");

    return "$hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Confirmation"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListTile(
        isThreeLine: true,
        title: Text(
            "${widget.transport.routeType?.name} ${widget.transport.route?.number} - ${widget.transport.direction?.name}"),
        subtitle: Text("${widget.transport.stop?.name}\n" // Stop Name
            "Next Departure: ${getTime(widget.transport.departures?[0].scheduledDeparture)}\n"), // Next Departure
        onTap: () {},
      ),
    );
  }
}
