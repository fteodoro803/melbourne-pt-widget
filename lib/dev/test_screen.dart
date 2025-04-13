import 'package:flutter/material.dart';
import 'package:flutter_project/database/helpers/routeStopsHelpers.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as ptv;
import 'package:get/get.dart';
import '../database/database.dart' as db;

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  PtvService ptvService = PtvService();
  final TextEditingController routeQuery = TextEditingController();
  final TextEditingController routeTypeIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
  }

  @override
  void dispose() {
    routeQuery.dispose();
    routeTypeIdController.dispose();
    super.dispose();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
    await Future.delayed(Duration(milliseconds: 100));
  }

  ptv.Route route = ptv.Route(id: 725, name: "name", number: "1", type: RouteType.tram, gtfsId: "gtfsId", status: "status");
  RouteDirection direction = RouteDirection(id: 10, name: "name", description: "description");
  Future<void> fetchStopsRoute() async {
    // also do a fetch route stops here
    var stops = await ptvService.fetchStopsRoute(route);
    await Future.delayed(Duration(milliseconds: 100));
    print(stops);
  }
  Future<void> getStopsRoute() async {
    // also do a fetch route stops here
    var database = Get.find<db.AppDatabase>();
    var dataStopsRoute = await database.getStopsOnRoute(route.id);
    await Future.delayed(Duration(milliseconds: 100));
    print(dataStopsRoute.toString());
  }

  Future<void> searchRoutes(String? query, int? routeType) async {
    var database = Get.find<db.AppDatabase>();
    var routeList = await ptvService.searchRoutes(query: query, routeType: routeType != null ? RouteType.fromId(routeType) : null);
    print(routeList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Column(
        children: [
          ElevatedButton(onPressed: () {
            getStopsRoute();
          }, child: Text("fetchStopsRoute")),
          ElevatedButton(onPressed: () {
            getStopsRoute();
          }, child: Text("getStopsRoute")),
          Divider(),
          TextField(
            controller: routeQuery,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Route Query"),
          ),
          TextField(
            controller: routeTypeIdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Route Type ID"),
          ),
          ElevatedButton(onPressed: () {
            searchRoutes(routeQuery.text, int.tryParse(routeTypeIdController.text));
          }, child: Text("Search Route")),
        ],
      ),
    );
  }
}
