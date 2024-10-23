import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_api_service.dart';
import 'package:flutter_project/screen_arguments.dart';

class SelectDirectionScreen extends StatefulWidget {
  const SelectDirectionScreen({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<SelectDirectionScreen> createState() => _SelectDirectionScreenState();
}

class _SelectDirectionScreenState extends State<SelectDirectionScreen> {
  String _screenName = "selectDirection";
  List<RouteDirection> _directions = [];
  DevTools tools = DevTools();

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchRouteDirections();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  void fetchRouteDirections() async {
    String? routeId =
        widget.arguments.transport.route?.id; // this seems a bit convoluted

    // Fetching Data and converting to JSON
    Data data = await PtvApiService().routeDirections(routeId!);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("NULL DATA RESPONSE --> Improper Location Data");
      return;
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      // if (direction["route_id"] != widget.userSelections.stop?.route.id) {continue;}

      String id = direction["direction_id"].toString();
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      RouteDirection newDirection =
          RouteDirection(id: id, name: name, description: description);

      _directions.add(newDirection);
    }

    setState(() {});
  }

  void setDirection(index) {
    widget.arguments.transport.direction = _directions[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Direction:"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListView.builder(
        // old
        itemCount: _directions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title:
                Text("${_directions[index].name} (${_directions[index].id})"),
            onTap: () {
              setDirection(index);
              Navigator.pushNamed(context, '/confirmationScreen',
                  arguments: ScreenArguments(widget.arguments.transport));
            },
          );
        },
      ),
    );
  }
}
