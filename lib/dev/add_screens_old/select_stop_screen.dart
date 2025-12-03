import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/services/ptv_service.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/domain/route.dart' as PTRoute;
import 'package:get/get.dart';
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
  PtvService ptvService = Get.find<PtvService>();
  db.Database database = Get.find<db.Database>();

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
    String? location = widget.arguments.testLocation?.coordinates;
    int? routeType = widget.arguments.selectedRouteType?.id;
    int maxDistance = 300;

    // Create temporary lists to hold the new data
    List<Stop> newStops = [];
    List<PTRoute.Route> newRoutes = [];
    List<Stop> stopList = await ptvService.stops.fetchStopsByLocation(
        location: location!, routeType: routeType!, maxDistance: maxDistance);
    List<Future<void>> routeFetchOperations =
        []; // holds all route fetch operations

    for (var stop in stopList) {
      // Add the future operation to list instead of awaiting it immediately
      routeFetchOperations
          .add(ptvService.routes.fetchRoutesFromStop(stop.id).then((routeList) {
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
    widget.arguments.trip!.stop = _stops[index];
    widget.arguments.trip!.route = _routes[index];

    int routeId = _routes[index].id;
    String routeName = _routes[index].name;
    int routeTypeId = _routes[index].type.id;
    String routeNumber = _routes[index].number;
    // String gtfsId = _routes[index].gtfsId;
    String status = _routes[index].status;

    var dbRoute = database.routesDao.createRouteCompanion(
        id: routeId,
        name: routeName,
        number: routeNumber,
        routeTypeId: routeTypeId,
        status: status
    );
    database.routesDao.addRoute(dbRoute);

    int stopId = _stops[index].id;
    String stopName = _stops[index].name;
    double? latitude = _stops[index].latitude;
    double? longitude = _stops[index].longitude;

    var dbStop = database.stopsDao.createStopCompanion(id: stopId, name: stopName, latitude: latitude!, longitude: longitude!);
    database.stopsDao.addStop(dbStop);
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
