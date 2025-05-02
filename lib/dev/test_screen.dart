import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/api/gtfs_api_service.dart';
import 'package:flutter_project/services/gtfs_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  PtvService ptvService = PtvService();
  GtfsApiService gtfsApiService = GtfsApiService();
  GtfsService gtfsService = GtfsService();
  final TextEditingController gtfsRouteId = TextEditingController();
  List<Trip> transportList = [];

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
    _loadTransports();
  }

  @override
  void dispose() {
    gtfsRouteId.dispose();
    super.dispose();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> _loadTransports() async {
    transportList = await ptvService.loadTrips();

    setState(() {});
  }

  Future<void> gtfsTest(String id) async {
    int ptvRouteId = int.tryParse(id) != null ? int.parse(id) : 0;

    // var gtfsResponse = await gtfsService.fetchGeoPath(routeId);
    // var gtfsResponse = await gtfsService.getTramTripUpdates();

    //
    // print(gtfsResponse.toString());
  }

  Future<void> initialiseGtfsService() async {
    gtfsService.initialise();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Column(
        children: [
          ElevatedButton(onPressed: initialiseGtfsService, child: Text("Initialise GTFS Service")),
          Divider(),
          TextField(
            controller: gtfsRouteId,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Gtfs Route Id"),
          ),
          ElevatedButton(onPressed: () {
            gtfsTest(gtfsRouteId.text);
          }, child: Text("Gtfs Test")),
        ],
      ),
    );
  }
}

