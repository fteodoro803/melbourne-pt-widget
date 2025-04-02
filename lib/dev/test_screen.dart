import 'package:flutter/material.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {

  void testFunct(String location, {Map<String, Object>? parameters}) {
    var parameters = {
      'routeTypes': ['1', '2'],
      'color': ['red', 'blue'],
      'maxResults': '5',
      'maxDistance': '30',
    };
  }

  void getStops() {}

  @override
  Widget build(BuildContext context) {
    String location = "loc";
    String? routeTypes = "1,2,3";
    String? maxResults = "3";
    String? maxDistance = null;

    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: ElevatedButton(onPressed: () {
      }, child: Text("BoolTest")),
    );
  }
}
