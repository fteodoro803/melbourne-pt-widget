import 'package:flutter/material.dart';
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
  final List<RouteType> _routeTypesClass = [];
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
    Data data = await PtvApiService().routeTypes();
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
      RouteType newRouteType = RouteType(name: name, type: type);

      _routeTypesClass.add(newRouteType);
    }

    setState(() {});
  }

  void setRouteType(int index) {
    widget.arguments.transport.routeType = _routeTypesClass[index];
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
        itemCount: _routeTypesClass.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_routeTypesClass[index].name),
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
