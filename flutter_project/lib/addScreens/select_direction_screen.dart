import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/ptvInfoClasses/RouteDirectionInfo.dart';
import 'package:flutter_project/ptv_api_service.dart';
import '../transport.dart';

class SelectDirectionScreen extends StatefulWidget {
  const SelectDirectionScreen({super.key, required this.transport});

  final Transport transport;

  @override
  State<SelectDirectionScreen> createState() => _SelectDirectionScreenState();
}

class _SelectDirectionScreenState extends State<SelectDirectionScreen> {
  String _screenName = "Direction";
  List<RouteDirection> _directions = [];

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

  void fetchRouteDirections() async {
    String? routeId = widget.transport.route?.id; // this seems a bit convoluted

    // Fetching Data and converting to JSON
    Data data = await PtvApiService().routeDirections(routeId!);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {print("NULL DATA RESPONSE --> Improper Location Data"); return;}

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      // if (direction["route_id"] != widget.userSelections.stop?.route.id) {continue;}

      String id = direction["direction_id"].toString();
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      RouteDirection newDirection = RouteDirection(id: id, name: name, description: description);

      _directions.add(newDirection);
    }

    setState(() {});
  }

  void setDirection(index) {
    widget.transport.direction = _directions[index];

    // TestPrint
    if (kDebugMode) {
      print(widget.transport);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Direction:"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListView.builder(      // old
        itemCount: _directions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${_directions[index].name} (${_directions[index].id})"),
            onTap: () {
              setDirection(index);
              Navigator.pushNamed(context, '/confirmationScreen');
            },

          );
        },
      ),
    );
  }
}
