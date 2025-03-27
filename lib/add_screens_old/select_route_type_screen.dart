import 'package:flutter/material.dart';
import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/ptv_api_service.dart';
import 'package:flutter_project/dev/dev_tools.dart';

class SelectRouteTypeScreen extends StatefulWidget {
  // Constructor
  const SelectRouteTypeScreen({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<SelectRouteTypeScreen> createState() => _SelectRouteTypeScreenState();
}

class _SelectRouteTypeScreenState extends State<SelectRouteTypeScreen> {
  // PtvApiService apiService = PtvApiService();

  final String _screenName = "SelectRouteType";
  final List<RouteType> _routeTypes = [];
  DevTools tools = DevTools();

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchRouteTypes();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  // Fetches Routes and generates Map/Dictionary of PT Options               // I dont like how this logic is in the same file as the frontend rendering, find a way to split this
  Future<void> fetchRouteTypes() async {
    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeTypes();
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit     // Make it display on screen if there is no data
    if (data.response == null) {
      print("NULL DATA RESPONSE --> Improper Location Data");
      return;
    }

    // Populating RouteTypes List                                                         // add case for if 0
    for (var entry in jsonResponse!["route_types"]) {
      String name = entry["route_type_name"];
      String type = entry["route_type"].toString();
      // RouteType newRouteType = RouteType(name: name, type: type);

      switch (name.toLowerCase()) {
        case "train":
          _routeTypes.add(RouteType(type: RouteTypeEnum.train));
        case "tram":
          _routeTypes.add(RouteType(type: RouteTypeEnum.tram));
        case "bus":
          _routeTypes.add(RouteType(type: RouteTypeEnum.bus));
        case "vline":
          _routeTypes.add(RouteType(type: RouteTypeEnum.vLine));
        case "night bus":
          _routeTypes.add(RouteType(type: RouteTypeEnum.nightBus));
      }
     }

    setState(() {});
  }

  void setRouteType(int index) {
    widget.arguments.transport.routeType = _routeTypes[index];
  }

  // Rendering
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select PTV:"),
        centerTitle: true,
      ),

      // Generates List of Options
      body: ListView.builder(
        // old
        itemCount: _routeTypes.length,
        itemBuilder: (context, index) {
          final routeTypeName = _routeTypes[index].type.name ?? "Unknown RouteType";

          return ListTile(
            title: Text(routeTypeName),
            onTap: () {
              setRouteType(index);
              Navigator.pushNamed(context, '/selectLocationScreen',
                  arguments: widget.arguments);
            },
          );
        },
      ),
    );
  }
}
