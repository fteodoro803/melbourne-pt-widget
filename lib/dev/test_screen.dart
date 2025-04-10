import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
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

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
  }

  ptv.Route route = ptv.Route(id: 725, name: "name", number: "1", type: RouteType.tram, gtfsId: "gtfsId", status: "status");
  RouteDirection direction = RouteDirection(id: 10, name: "name", description: "description");
  Future<void> getStopsRoute() async {
    // also do a fetch route stops here
    var stops = await ptvService.getStopsRoute(route);
    print(stops);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: ElevatedButton(onPressed: () {
        getStopsRoute();
      }, child: Text("getStopsRoute")),
    );
  }
}
