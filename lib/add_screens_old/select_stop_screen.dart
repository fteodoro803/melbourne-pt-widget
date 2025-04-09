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
  List<PTRoute.Route> _routes = [];
  DevTools tools = DevTools();
  PtvService ptvService = PtvService();

  // Initialising State
  @override
  void initState() {
    super.initState();
    getStopsAndRoutes();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }


  // Fetch each Route that each Stop is on
  Future<void> getStopsAndRoutes() async {
    String? location = widget.arguments.transport.location?.coordinates;
    int? routeType = widget.arguments.transport.routeType?.id;
    int maxDistance = 300;

    // Create temporary lists to hold the new data
    List<Stop> newStops = [];
    List<PTRoute.Route> newRoutes = [];
    List<Stop> stopList = await ptvService.fetchStopsLocation(location!, routeType: routeType!, maxDistance: maxDistance);
    List<Future<void>> routeFetchOperations = [];      // holds all route fetch operations

    for (var stop in stopList) {

      // Add the future operation to list instead of awaiting it immediately
      routeFetchOperations.add(ptvService.fetchRoutesFromStop(stop.id).then((routeList) {
        print("select stop screen -- RouteList for Stop${stop.id} $routeList");

        for (var route in routeList) {
          if (route.type.id != routeType) {
            continue;
          }

          newStops.add(stop);
          newRoutes.add(route);
        }
      }));
    }

    // Wait for ALL route fetch operations to complete
    await Future.wait(routeFetchOperations);

    // Now that everything is complete, update the actual data and state
    setState(() {
      _stops = newStops;
      _routes = newRoutes;
    });
  }

  void setStopAndRoute(index) {
    widget.arguments.transport.stop = _stops[index];
    widget.arguments.transport.route = _routes[index];

    int routeId = _routes[index].id;
    String routeName = _routes[index].name;
    int routeTypeId = _routes[index].type.id;
    String routeNumber = _routes[index].number;
    String status = _routes[index].status;
    Get.find<db.AppDatabase>().addRoute(routeId, routeName,routeNumber , routeTypeId, status);

    int stopId = _stops[index].id;
    String stopName = _stops[index].name;
    double? latitude = _stops[index].latitude;
    double? longitude = _stops[index].longitude;
    Get.find<db.AppDatabase>().addStop(stopId, stopName, latitude!, longitude!);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Stop & Route:"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListView.builder(
        // old
        itemCount: _stops.length,
        itemBuilder: (context, index) {
          final stopName = _stops[index].name;
          final routeNumber = _routes[index].number;
          // String routeNumber = "rNumber";     // get these from database
          final routeName = _routes[index].name;
          // String routeName = "rName";         // get these from database

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
