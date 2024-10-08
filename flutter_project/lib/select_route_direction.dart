import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'selections.dart';

class SelectRouteDirection extends StatefulWidget {
  const SelectRouteDirection({super.key, required this.userSelections});

  final Selections userSelections;

  @override
  State<SelectRouteDirection> createState() => _SelectRouteDirectionState();
}

class _SelectRouteDirectionState extends State<SelectRouteDirection> {
  String _screenName = "RouteDirections";

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchRouteDirections();

    // Debug Printing
    if (kDebugMode) {
      print("Screen: $_screenName");
    }
  }

  void fetchRouteDirections() {
  }


  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
