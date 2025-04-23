import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/api/gtfs_api_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  PtvService ptvService = PtvService();
  GtfsApiService gtfsApiService = GtfsApiService();
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

  Future<void> gtfsTest(String gtfsId) async {
    var gtfsResponse = await gtfsApiService.getTripUpdatesRoute(gtfsId);

    print(gtfsResponse.toString());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Column(
        children: [
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

