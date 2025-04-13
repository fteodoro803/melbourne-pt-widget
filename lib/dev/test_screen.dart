import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  PtvService ptvService = PtvService();
  final TextEditingController inputField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialisePTVData();
  }

  @override
  void dispose() {
    inputField.dispose();
    super.dispose();
  }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> directions(int routeId) async {
    var directionList = await ptvService.fetchDirections(routeId);
    print(directionList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Column(
        children: [
          TextField(
            controller: inputField,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Route Id"),
          ),
          ElevatedButton(onPressed: () {
            directions(int.parse(inputField.text));
          }, child: Text("Get Route Directions")),
        ],
      ),
    );
  }
}
