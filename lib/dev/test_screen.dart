import 'package:flutter/material.dart';
import 'package:flutter_project/database/helpers/routeHelpers.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/domain/route_info.dart' as ptv;
import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/domain/trip.dart';
import 'package:get/get.dart';

import '../add_screens/widgets/custom_list_tile.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  PtvService ptvService = PtvService();
  final TextEditingController locationField = TextEditingController();
  List<Trip> transportList = [];

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
    _loadTransports();
  }

  @override
  void dispose() {
    locationField.dispose();
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

  Future<void> fromDbTest() async {
    int routeId = 725;

    var database = Get.find<db.AppDatabase>();
    var dbRoute = await database.getRouteById(routeId);

    print("Db Route: ${dbRoute.toString()}");

    ptv.Route? domainRoute = dbRoute != null ? ptv.Route.fromDb(dbRoute) : null;
    print("Domain Route: $domainRoute");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      // body: Column(
      //   children: [
      //     // TextField(
      //     //   controller: locationField,
      //     //   keyboardType: TextInputType.number,
      //     //   decoration: InputDecoration(labelText: "Location"),
      //     // ),
      //     // ElevatedButton(onPressed: () {
      //     //   fromDbTest();
      //     // }, child: Text("FromDb - Route")),
      //   ],
      // ),

      body: ListView.builder(
        itemCount: transportList.length,
        itemBuilder: (context, index) {
          final transport = transportList[index];
          return CustomListTile(
              transport: transport,
              onTap: () {
                print("DB Transport Info:\n$transport");
              });
        },
      ),
    );
  }
}
