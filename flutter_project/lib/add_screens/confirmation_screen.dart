// Shows a Sample of what the Transit Departure Screen will display
// Also is a confirmation, which leads back to the home page

import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Confirmation"),
        centerTitle: true,
      ),

      // Generates Example of Stop
      body: CustomListTile(transport: transport),
    );
  }
}
