import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/selections.dart';
import 'ptv_api_service.dart';
import 'ptvInfoClasses/StopInfo.dart';

class SelectStopScreen extends StatefulWidget {
  const SelectStopScreen({super.key, required this.userSelections});

  final Selections userSelections;

  @override
  State<SelectStopScreen> createState() => _SelectStopScreenState();
}

class _SelectStopScreenState extends State<SelectStopScreen> {
  String _screenName = "SelectStop";
  List<Stop> _stops = [];

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchStops();

    // Debug Printing
    if (kDebugMode) {
      print("Screen: $_screenName\n${widget.userSelections}");
    }
  }

  // Fetch Stops            -- do tests to see if not null
  Future<void> fetchStops() async {
    String? location = widget.userSelections.selectedLocation;
    String? routeType = widget.userSelections.routeType;

    // Fetching Data and converting to JSON
    Data data = await PtvApiService().stops(location!, routeTypes: routeType);
    Map<String, dynamic> jsonResponse = jsonDecode(data.response);

    // Populating Stops List
    for (var stop in jsonResponse["stops"]) {
      for (var route in stop["routes"]) {
        if (route["route_type"].toString() != widget.userSelections.routeType) {continue;}

        Stop newStop = Stop();
        newStop.id = stop["stop_id"].toString();
        newStop.name = stop["stop_name"];
        newStop.suburb = stop["suburb"];

        newStop.routeName = route["route_name"];
        newStop.routeNumber = route["route_number"];

        _stops.add(newStop);

      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Stop:"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListView.builder(      // old
        itemCount: _stops.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${_stops[index].name}: ${_stops[index].routeName!} (${_stops[index].routeNumber})"),
            onTap: () {            },
          );
        },
      ),
    );
  }
}
