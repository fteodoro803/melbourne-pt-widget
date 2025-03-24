import 'package:flutter/material.dart';
import 'package:flutter_project/api_data.dart';
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
  final String _screenName = "selectDirection";
  final List<RouteDirection> _directions = [];
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
    ApiData data = await PtvApiService().routeDirections(routeId!);
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

  void setDirection(int? index) {
    if (index != null) {
      widget.arguments.transport.direction = _directions[index];
    }
    else {
      widget.arguments.transport.direction = null;

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                // old
                itemCount: _directions.length,
                itemBuilder: (context, index) {
                  final directionName =
                      _directions[index].name ?? "Null directionName";
                  final directionId =
                      _directions[index].id ?? "Null directionId";

                  return ListTile(
                    title: Text("$directionName ($directionId)"),
                    onTap: () {
                      setDirection(index);
                      Navigator.pushNamed(context, '/confirmationScreen',
                          arguments: widget.arguments);
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
                onPressed: () => {
                  setDirection(null),
                  Navigator.pushNamed(context, '/confirmationScreen',
                          arguments: widget.arguments),
                },
                child: Text("Skip"))
          ],
        ),
      ),
    );
  }
}
