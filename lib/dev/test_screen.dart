import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/location_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as ptv;

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  PtvService ptvService = PtvService();
  final TextEditingController locationField = TextEditingController();
  final TextEditingController routeField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
  }

  @override
  void dispose() {
    locationField.dispose();
    routeField.dispose();
    super.dispose();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> directions(String location) async {
    Location newLocation = Location(coordinates: location);
    var stops = await ptvService.fetchStopsLocation("${newLocation.latitude},${newLocation.longitude}");
    print(stops);
  }

  Future<void> stops(int routeId) async {
    ptv.Route route = ptv.Route(id: routeId, name: "name", number: "number", type: RouteType.fromId(1), gtfsId: "gtfsId", status: "status");
    var stops = await ptvService.fetchStopsRoute(route);
    print(stops);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Column(
        children: [
          TextField(
            controller: locationField,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Location"),
          ),
          ElevatedButton(onPressed: () {
            directions(locationField.text);
          }, child: Text("Stops from a Location")),
          Divider(),
          TextField(
            controller: routeField,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Route ID"),
          ),
          ElevatedButton(onPressed: () {
            stops(int.parse(routeField.text));
          }, child: Text("Stops on a Route")),
        ],
      ),
    );
  }
}
