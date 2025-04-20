import 'package:flutter/material.dart';
import 'package:flutter_project/domain/route_type_info.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/screen_arguments.dart';
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
  PtvService ptvService = PtvService();

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchRouteTypes();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  // Fetches Routes and generates Map/Dictionary of PT Options
  Future<void> fetchRouteTypes() async {
    List<String> routeTypes = await ptvService.fetchRouteTypes();

    // Populating RouteTypes List
    for (var name in routeTypes) {
      switch (name.toLowerCase()) {
        case "train":
          _routeTypes.add(RouteType.train);
        case "tram":
          _routeTypes.add(RouteType.tram);
        case "bus":
          _routeTypes.add(RouteType.bus);
        case "vline":
          _routeTypes.add(RouteType.vLine);
        // case "night bus":      // todo: re-enable night bus later
        //   _routeTypes.add(RouteTypeEnum.nightBus);
      }
    }

    setState(() {});
  }

  void setRouteType(int index) {
    widget.arguments.trip!.routeType = _routeTypes[index];
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
          final routeTypeName = _routeTypes[index].name;

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
