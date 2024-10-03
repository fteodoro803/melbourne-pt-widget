// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'ptv_api_service.dart';
import 'dart:convert';

class SelectRouteTypeScreen extends StatefulWidget {
  const SelectRouteTypeScreen({super.key});

  @override
  State<SelectRouteTypeScreen> createState() => _SelectRouteTypeScreenState();
}

class _SelectRouteTypeScreenState extends State<SelectRouteTypeScreen> {
  PtvApiService apiService = PtvApiService();
  Map<int, String> routeTypes = {};
  String testOutput = '';

  @override
  void initState() {
    super.initState();
    fetchRouteTypes();
  }

  // Generates Map/Dictionary of PT Options               // I dont like how this logic is in the same file as the frontend rendering, find a way to split this
  Future<void> fetchRouteTypes() async {
    // Fetching Data and converting to JSON
    Data data = await PtvApiService().routeTypes();
    Map<String, dynamic> jsonResponse = jsonDecode(data.response);

    // Populating Map
    for (var entry in jsonResponse["route_types"]) {
      int routeTypeNumber = entry["route_type"];
      String routeTypeName = entry["route_type_name"];
      routeTypes[routeTypeNumber] = routeTypeName;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select PTV:"),
      ),
      body: ListView.builder(
        // Placeholder -- but from this point on, I want to render a clickable list of Routes from routeTypes. When clicked, these save to user preferences.
        itemCount: routeTypes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(routeTypes[index]!),
            onTap: () {

            },
          );
        },
      ),
    );
  }
}
