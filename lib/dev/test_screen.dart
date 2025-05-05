import 'package:flutter/material.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/services/gtfs_service.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  final TextEditingController ptvRouteId = TextEditingController();
  final TextEditingController ptvStopId = TextEditingController();
  final TextEditingController gtfsStopId = TextEditingController();
  final TextEditingController gtfsRouteId = TextEditingController();
  final TextEditingController gtfsTripId = TextEditingController();
  final TextEditingController ptvRouteIdTrips = TextEditingController();


  List<Trip> transportList = [];

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
  }

  @override
  void dispose() {
    ptvRouteId.dispose();
    ptvStopId.dispose();
    gtfsRouteId.dispose();
    gtfsStopId.dispose();
    gtfsTripId.dispose();
    ptvRouteIdTrips.dispose();
    super.dispose();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
    await Future.delayed(Duration(milliseconds: 100));
  }


  Future<void> departureStopTest(int stopId, bool gtfs) async {
    int routeType = 1;
    int maxResults = 1;
    String expand = "Direction";


    ptvApiService.departures(routeType.toString(), stopId.toString(),
        gtfs: gtfs,
        maxResults: maxResults.toString(),
        expand: expand,
    );
  }

  Future<void> tripGeoPathTest(String id) async {
    List<LatLng> geoPath = await gtfsService.fetchGeoPathShape(id);
    print(geoPath);
    print("GeoPath Length: ${geoPath.length}");
  }

  Future<void> tripShapeHeadsign(int id) async {
    var shapeHeadsignMap = await gtfsService.getShapes(id);
    print(shapeHeadsignMap.keys);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Column(
        children: [
          TextField(
            controller: ptvRouteId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Ptv Route Id"),
          ),
          TextField(
            controller: ptvStopId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Ptv Stop Id"),
          ),
          TextField(
            controller: gtfsRouteId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Gtfs Route Id"),
          ),
          TextField(
            controller: gtfsStopId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Gtfs Stop Id"),
          ),
          ElevatedButton(onPressed: () {
            departureStopTest(int.parse(ptvStopId.text), false);
          }, child: Text("Ptv Departure")),
          ElevatedButton(onPressed: () {
            departureStopTest(int.parse(gtfsStopId.text), true);
          }, child: Text("Gtfs Departure")),

          Divider(),

          TextField(
            controller: gtfsTripId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Gtfs Trip Id"),
          ),
          ElevatedButton(onPressed: () {
            tripGeoPathTest(gtfsTripId.text);
          }, child: Text("Trip GeoPath")),

          Divider(),
          TextField(
            controller: ptvRouteIdTrips,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "PTV Route ID"),
          ),
          ElevatedButton(onPressed: () {
            tripShapeHeadsign(int.parse(ptvRouteIdTrips.text));
          }, child: Text("Trip Shapes")),
        ],
      ),
    );
  }
}