import 'package:flutter/material.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/route_helpers.dart';
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/services/gtfs_service.dart';
import 'package:flutter_project/services/utility/list_extensions.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_project/domain/route.dart' as pt_route;
import 'package:flutter_project/database/database.dart' as db;

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
  var database = Get.find<AppDatabase>();

  // // Testing Routes and GTFS
  // final TextEditingController ptvRouteId = TextEditingController();
  // final TextEditingController ptvStopId = TextEditingController();
  // final TextEditingController gtfsStopId = TextEditingController();
  // final TextEditingController gtfsRouteId = TextEditingController();
  // final TextEditingController gtfsTripId = TextEditingController();
  // final TextEditingController ptvRouteIdTrips = TextEditingController();

  // Testing RouteStops fold
  final TextEditingController ptvRouteId1 = TextEditingController();
  final TextEditingController ptvRouteId2 = TextEditingController();
  final TextEditingController ptvStopId = TextEditingController();

  List<Trip> transportList = [];

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
  }

  @override
  void dispose() {
    ptvRouteId1.dispose();
    ptvRouteId2.dispose();
    ptvStopId.dispose();
    super.dispose();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> stopGroups({int? routeId1, int? routeId2, int? stopId}) async {
    print("( test_screen.dart -> stopGroups ) -- Stop ID: $stopId\nRoute IDs: $routeId1, $routeId2");
    if (routeId1 == null || routeId2 == null || stopId == null) {
      return;
    }

    // 1. Get Routes
    List<pt_route.Route> routes = [];
    var route1Data = await database.getRouteById(routeId1);
    pt_route.Route? route1 = route1Data != null ? pt_route.Route.fromDb(route1Data) : null;
    var route2Data = await database.getRouteById(routeId2);
    pt_route.Route? route2 = route2Data != null ? pt_route.Route.fromDb(route2Data) : null;

    if (route1 != null && route2 != null) {
      routes.add(route1);
      routes.add(route2);
    }

    // 2. Fold routes
    var group = ptvService.commonStops(routes, stopId);
  }

  void listTest() {
    List<int> list1 = [0,1,2,3,4,5,6,7,8,9];
    List<int> list2 = [7,8,9,10];

    List<int> shared = list1.sharedSublist(list2, 9);
    print(shared);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Column(
        children: [
          // TextField(
          //   controller: ptvRouteId,
          //   keyboardType: TextInputType.number,
          //   decoration: InputDecoration(labelText: "Ptv Route Id"),
          // ),
          // TextField(
          //   controller: ptvStopId,
          //   keyboardType: TextInputType.number,
          //   decoration: InputDecoration(labelText: "Ptv Stop Id"),
          // ),
          // TextField(
          //   controller: gtfsRouteId,
          //   keyboardType: TextInputType.number,
          //   decoration: InputDecoration(labelText: "Gtfs Route Id"),
          // ),
          // TextField(
          //   controller: gtfsStopId,
          //   keyboardType: TextInputType.number,
          //   decoration: InputDecoration(labelText: "Gtfs Stop Id"),
          // ),

          TextField(
            controller: ptvRouteId1,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Ptv Route Id 1"),
          ),
          TextField(
            controller: ptvRouteId2,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Ptv Route Id 2"),
          ),
          TextField(
            controller: ptvStopId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Ptv Stop Id"),
          ),

          Divider(),

          ElevatedButton(onPressed: () => stopGroups(routeId1: int.tryParse(ptvRouteId1.text), routeId2: int.tryParse(ptvRouteId2.text), stopId: int.tryParse(ptvStopId.text)), child: Text("Stop Groups")),

          Divider(),

          ElevatedButton(onPressed: listTest, child: Text("ListTest")),
        ],
      ),
    );
  }
}