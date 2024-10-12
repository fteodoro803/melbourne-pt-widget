// Shows a Sample of what the Transit Departure Screen will display
// Also is a confirmation, which leads back to the home page

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/ptvInfoClasses/DepartureInfo.dart';
import 'package:flutter_project/ptv_api_service.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/departure_service.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key, required this.transport});

  // Stores user Transport details
  final Transport transport;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String _screenName = "ConfirmationScreen";
  List<Departure> _departures = [];

  @override
  void initState() {
    super.initState();
    fetchDepartures();

    // Debug Printing
    if (kDebugMode) {
      print("Screen: $_screenName");
    }
  }

  // OLD FETCH DEPARTURES
  Future<void> fetchDepartures() async {
    // Fetching Data and converting to JSON
    String routeType = widget.transport.routeType!.type;
    String stopId = widget.transport.stop!.id;
    String directionId = widget.transport.direction!.id;
    String routeId = widget.transport.route!.id;
    String maxResults = "3";
    String expands = "All";   //test

    Data data = await PtvApiService().departures(routeType, stopId, directionId: directionId, routeId: routeId, maxResults: maxResults, expand: expands);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit     // Make it display on screen if there is no data
    if (data.response == null) {print("NULL DATA RESPONSE --> Improper Location Data"); return;}

    // Populating RouteTypes List                                                         // add case for if 0
    String? fetchedScheduledDeparture;
    String? fetchedEstimatedDeparture;
    DateTime? scheduledDepartureUTC;
    DateTime? estimatedDepartureUTC;

    for (var departure in jsonResponse!["departures"]) {
      fetchedScheduledDeparture = departure["scheduled_departure_utc"];
      scheduledDepartureUTC = fetchedScheduledDeparture != null ? DateTime.parse(fetchedScheduledDeparture) : null;

      fetchedEstimatedDeparture = departure["estimated_departure_utc"];
      estimatedDepartureUTC = fetchedEstimatedDeparture != null ? DateTime.parse(fetchedEstimatedDeparture) : null;

      Departure newDeparture = Departure(scheduledDepartureUTC: scheduledDepartureUTC, estimatedDepartureUTC: estimatedDepartureUTC);
      _departures.add(newDeparture);
    }

    setState(() {    });
  }

  // // NEW FETCH DEPARTURES
  // Future<void> fetchDepartures() async {
  //   String routeType = widget.transport.routeType!.type;
  //   String stopId = widget.transport.stop!.id;
  //   String directionId = widget.transport.direction!.id;
  //   String routeId = widget.transport.route!.id;
  //
  //   // Gets Departures
  //   DepartureService departureService = DepartureService();
  //   List<Departure> fetchedDepartures = await departureService.fetchDepartures(routeType, stopId, directionId, routeId);
  //
  //   setState(() {
  //     _departures = fetchedDepartures;
  //     // widget.transport.departures = fetchedDepartures;
  //   });
  // }

  // Returns the Time from a DateTime variable
  String? getTime(DateTime? dateTime) {
    if (dateTime == null) { return null; }

    // Adds a '0' to the left, if Single digit time (ex: 7 becomes 07)
    String hour = dateTime.hour.toString().padLeft(2,"0");
    String minute = dateTime.minute.toString().padLeft(2,"0");

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
      body: ListView.builder(      // old
        itemCount: _departures.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("Scheduled: ${getTime(_departures[index].scheduledDeparture)}"),
            subtitle: Text("Estimated: ${getTime(_departures[index].estimatedDeparture)}"),
            onTap: () {},

          );
        },
      ),
    );
  }
}
