import 'package:flutter/material.dart';
import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/database/helpers/stopHelpers.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/ptv_api_service.dart';
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
  final List<Stop> _stops = [];
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

  // TEST get Routes
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

  // Fetch Stops            -- do tests to see if not null      // todo: move this to ptv service
  Future<void> fetchStops() async {
    String? location = widget.arguments.transport.location?.coordinates;
    // print(location);
    String? routeType = widget.arguments.transport.routeType?.id.toString();
    // print(routeType);
    String? maxDistance = "300";

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().stops(location!, routeTypes: routeType, maxDistance: maxDistance);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("NULL DATA RESPONSE --> Improper Location Data");
      return;
    }

    // Populating Stops List
    for (var stop in jsonResponse!["stops"]) {
      for (var route in stop["routes"]) {
        if (route["route_type"] !=
            widget.arguments.transport.routeType!.id) {
          continue;
        }

        int stopId = stop["stop_id"];
        String stopName = stop["stop_name"];
        double latitude = stop["stop_latitude"];
        double longitude = stop["stop_longitude"];
        double? distance = stop["stop_distance"];
        Stop newStop = Stop(id: stopId, name: stopName, latitude: latitude, longitude: longitude, distance: distance);

        String routeName = route["route_name"];
        String routeNumber = route["route_number"].toString();
        int routeId = route["route_id"];
        int routeTypeId = route["route_type"];
        RouteType routeType = RouteType.fromId(routeTypeId);
        String status = "NULL -- TEST VALUE";     // todo fix this

        PTRoute.Route newRoute = PTRoute.Route(name: routeName, number: routeNumber, id: routeId, type: routeType, status: status);

        _stops.add(newStop);
        _routes.add(newRoute);
      }
    }

    setState(() {});
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
          final routeNumber = _routes[index].number;
          final routeName = _routes[index].name;

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
