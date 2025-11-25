import 'package:flutter/material.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/route_helpers.dart';
import 'package:flutter_project/services/ptv_service.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/services/gtfs_service.dart';
import 'package:get/get.dart';
import 'package:flutter_project/domain/route.dart' as pt_route;

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  PtvApiService ptvApiService = PtvApiService();
  PtvService ptvService = PtvService();
  GtfsApiService gtfsApiService = GtfsApiService();
  GtfsService gtfsService = GtfsService();
  var database = Get.find<Database>();

  // // Testing Routes and GTFS
  // final TextEditingController ptvRouteId = TextEditingController();
  // final TextEditingController ptvStopId = TextEditingController();
  // final TextEditingController gtfsStopId = TextEditingController();
  // final TextEditingController gtfsRouteId = TextEditingController();
  // final TextEditingController gtfsTripId = TextEditingController();
  // final TextEditingController ptvRouteIdTrips = TextEditingController();

  // Testing RouteStops fold
  List<TextEditingController> ptvRouteControllers = [];
  final TextEditingController ptvStopId = TextEditingController();

  List<Trip> transportList = [];

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
    _initialiseGTFSData();

    ptvRouteControllers = List.generate(1, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var controller in ptvRouteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.routeTypes.fetchRouteTypes();
    await ptvService.routes.fetchRoutes();
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> _initialiseGTFSData() async {
    await gtfsService.initialise();
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> stopGroups({List<int>? routeIds, int? stopId}) async {
    print(
        "( test_screen.dart -> stopGroups ) -- Stop ID: $stopId\tRoute IDs: $routeIds");
    if (routeIds == null || routeIds.isEmpty || stopId == null) {
      return;
    }

    // 1. Get Routes
    List<pt_route.Route> routes = [];
    for (final routeId in routeIds) {
      var data = await database.getRouteById(routeId);
      if (data != null) {
        // var route = pt_route.Route.fromDb(data);
        var route = await pt_route.Route.fromDbAsync(data);

        if (route != null) {
          pt_route.Route nonNullRoute = route;
          routes.add(nonNullRoute);
        }
      }
    }

    if (routes.isEmpty) {
      print("Not enough valid routes");
      return;
    }

    // 2. Fold routes
    var group =
        await ptvService.stops.splitStop(routes: routes, stopId: stopId);
    print(group);
  }

  Future<void> gtfsTest() async {
    await gtfsService.getTramTripUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Test Screen")),
        body: Column(
          children: [
            TextField(
              controller: ptvStopId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Ptv Stop Id"),
            ),
            ...ptvRouteControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: "Ptv Route Id ${index + 1}"),
              );
            }).toList(),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  ptvRouteControllers.add(TextEditingController());
                });
              },
              child: Text("Add Route Field"),
            ),
            ElevatedButton(
              onPressed: () {
                List<int> routeIds = ptvRouteControllers
                    .map((c) => int.tryParse(c.text))
                    .whereType<int>()
                    .toList();
                int? stopId = int.tryParse(ptvStopId.text);
                if (routeIds.isNotEmpty && stopId != null) {
                  stopGroups(routeIds: routeIds, stopId: stopId);
                } else {
                  print("Need at least 1 valid route ID and a stop ID");
                }
              },
              child: Text("Stop Groups"),
            ),
            ElevatedButton(
              onPressed: () {
                _initialiseGTFSData();
              },
              child: Text("Initialise"),
            ),
            ElevatedButton(
              onPressed: () {
                gtfsTest();
              },
              child: Text("Gtfs"),
            ),
          ],
        ));
  }
}
