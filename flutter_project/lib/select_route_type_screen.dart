// import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'ptv_api_service.dart';
import 'dart:convert';
import 'selections.dart';
import 'ptvInfoClasses/routeTypeInfo.dart';

class SelectRouteTypeScreen extends StatefulWidget {
  // Constructor
  const SelectRouteTypeScreen({super.key, required this.userSelections});

  // Stores User Selections
  final Selections userSelections;

  @override
  State<SelectRouteTypeScreen> createState() => _SelectRouteTypeScreenState();
}

class _SelectRouteTypeScreenState extends State<SelectRouteTypeScreen> {
  PtvApiService apiService = PtvApiService();
  String _screenName = "SelectRouteType";
  List<RouteType> _routeTypesClass = [];

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchRouteTypes();

    // Debug Printing
    if (kDebugMode) {
      print("Screen: $_screenName\n${widget.userSelections}");
    }
  }

  // Fetches Routes and generates Map/Dictionary of PT Options               // I dont like how this logic is in the same file as the frontend rendering, find a way to split this
  Future<void> fetchRouteTypes() async {
    // Fetching Data and converting to JSON
    Data data = await PtvApiService().routeTypes();
    Map<String, dynamic> jsonResponse = jsonDecode(data.response);

    // Populating RouteTypes List                                                         // add case for if 0
    for (var entry in jsonResponse["route_types"]) {
      RouteType newRouteType = RouteType();
      newRouteType.type = entry["route_type"].toString();
      newRouteType.name = entry["route_type_name"];

      _routeTypesClass.add(newRouteType);
    }

    setState(() {});
  }

  // Rendering
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select PTV:"),
        centerTitle: true,
      ),

      // Generates List of Options
      body: ListView.builder(      // old
        itemCount: _routeTypesClass.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_routeTypesClass[index].name!),
            onTap: () {
              widget.userSelections.routeType = _routeTypesClass[index].type;
              widget.userSelections.routeTypeName = _routeTypesClass[index].name;
              Navigator.pushNamed(context, '/selectLocationScreen');
            },
          );
        },
      ),
    );
  }
}
