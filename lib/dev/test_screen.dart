import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_service.dart';
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  var ptvService = PtvService();
  String routeTypes = "1,2,3";

  // 19 tram
  String routeType = "1";
  String routeId = "725";
  String stopId = "2718";
  String maxResults = "2";
  String expand = "Stop,Route";

  void testFunc() {
    ptvService.fetchDepartures(routeType, stopId, routeId, expands: expand, maxResults: maxResults);
    
    
    
  }

  void getStops() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: ElevatedButton(onPressed: () {
        testFunc();
      }, child: Text("ExpandsRouteTypesTest")),
    );
  }
}
