import 'package:flutter/material.dart';
import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/database/helpers/stopHelpers.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as PTRoute;
import 'package:google_maps_flutter/google_maps_flutter.dart'; // to avoid conflict with material's "Route"
import 'package:get/get.dart';
import 'package:flutter_project/database/helpers/routeHelpers.dart';
import 'package:flutter_project/database/database.dart' as db;

class SelectStopScreen extends StatefulWidget {
  const SelectStopScreen({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<SelectStopScreen> createState() => _SelectStopScreenState();
}

class _SelectStopScreenState extends State<SelectStopScreen> {
  final String _screenName = "SelectStop";
  List<Stop> _stops = [];
  final List<PTRoute.Route> _routes = [];
  DevTools tools = DevTools();
  PtvService ptvService = PtvService();

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchStops();

    //test
    getRoutes();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }


  // Fetch Stops
  Future<void> fetchStops() async {
    String? location = widget.arguments.transport.location?.coordinates;
    int? routeType = widget.arguments.transport.routeType?.id;
    int maxDistance = 300;

    List<Stop> stopList = await ptvService.fetchStopsLocation(location!, routeType!, maxDistance);
    _stops = stopList;

    setState(() {});
  }

  // TEST get Routes, can delete this, move it to main on initialisation
  Future<void> getRoutes() async {
    List<PTRoute.Route> routeList = await ptvService.fetchRoutes();

    for (var route in routeList) {
      int id = route.id;
      String name = route.name;
      int routeTypeId = route.type.id;
      int? number = int.tryParse(route.number);
      String status = route.status;

      await Get.find<db.AppDatabase>().addRoute(id, name, routeTypeId, status, number: number);
    }
  }

  void setStopAndRoute(index) {
    widget.arguments.transport.stop = _stops[index];
    widget.arguments.transport.route = _routes[index];

    int routeId = _routes[index].id;
    String routeName = _routes[index].name;
    int routeTypeId = _routes[index].type.id;
    int? routeNumber;
    String status = _routes[index].status;
    if (_routes[index].number.isNotEmpty) {
      routeNumber = int.tryParse(_routes[index].number);
    }
    Get.find<db.AppDatabase>().addRoute(routeId, routeName, routeTypeId, status, number: routeNumber);

    int stopId = _stops[index].id;
    String stopName = _stops[index].name;
    double? latitude = _stops[index].latitude;
    double? longitude = _stops[index].longitude;
    Get.find<db.AppDatabase>().addStop(stopId, stopName, routeTypeId, latitude!, longitude!);

  }

  Future<void> testFetchStopRoutePairs(LatLng location) async {
    StopRouteLists stopRouteLists = await ptvService.fetchStopRoutePairs(location);
    print("stopRouteLists.routes (${stopRouteLists.routes.length}) = \n${stopRouteLists.routes}");
    print("stopRouteLists.stops (${stopRouteLists.stops.length}) = \n${stopRouteLists.stops}");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Stop:"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListView.builder(
        // old
        itemCount: _stops.length,
        itemBuilder: (context, index) {
          final stopName = _stops[index].name;
          // final routeNumber = _routes[index].number;
          String routeNumber = "rNumber";     // get these from database
          // final routeName = _routes[index].name;
          String routeName = "rName";         // get these from database

          return ListTile(
            title: Text("$stopName: ($routeNumber)"),
            subtitle: Text(routeName),
            onTap: () {
              setStopAndRoute(index);
              Navigator.pushNamed(context, '/selectDirectionScreen',
                  arguments: widget.arguments);
            },
          );
        },
      ),
    );
  }
}
