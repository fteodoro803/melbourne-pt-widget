// Shows a Sample of what the Transit Departure Screen will display
// Also is a confirmation, which leads back to the home page

import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/services/ptv_service.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/add_screens/widgets/custom_list_tile.dart';

import 'package:flutter_project/domain/trip.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String _screenName = "ConfirmationScreen";
  PtvService ptvService = PtvService();
  DevTools tools = DevTools();
  List<Trip> transportList = [];
  bool _isLoading = true;

  @override
  void initState() {
    initialiseData();

    super.initState();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  Future<void> initialiseData() async {
    await _setTransportList();
    await _initialiseDepartures();

    setState(() {
      _isLoading = false;
    });
  }

  // Updates UI as a result of Update Departures
  Future<void> _initialiseDepartures() async {
    // print("( confirmation_screen.dart -> _initialiseDepartures() ) -- transportList = $transportList");
    for (int i = 0; i < transportList.length; i++) {
      // print("( confirmation_screen.dart -> _initialiseDepartures() ) -- transportList[$i] = ${transportList[i]}");
      await transportList[i].updateDepartures();
    }

    // setState(() {});
  }

  Future<void> _setTransportList() async {
    // print("( confirmation_screen.dart -> _setTransportList() ) -- direction = ${widget.arguments.transport.direction}");
    if (widget.arguments.trip!.direction != null) {
      final transport = widget.arguments.trip;
      transportList.add(transport!);
    } else {
      // print("( confirmation_screen.dart -> _setTransportList() ) -- splitting transport by direction");
      transportList = await widget.arguments.trip!.splitByDirection();
      // print("( confirmation_screen.dart -> _setTransportList() ) -- done splitting transport by direction: $transportList");
    }

    // setState(() {});
  }

  Future<void> _saveTransportToDb(Trip transport) async {
    await ptvService.trips.saveTrip(transport);
  }

  // Generate

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    else {
      return Scaffold(
        appBar: AppBar(
          title: Text("Confirmation"),
          centerTitle: true,
        ),

        body: ListView.builder(
          itemCount: transportList.length,
          itemBuilder: (context, index) {
            final transport = transportList[index];
            return CustomListTile(
                trip: transport,
                onTap: () async {
                  await _saveTransportToDb(transport);
                  widget.arguments
                      .callback(); // calls the screen arguments callback function
                  Navigator.popUntil(context, ModalRoute.withName("/"));
                });
          },
        ),
      );
    }
  }
}
