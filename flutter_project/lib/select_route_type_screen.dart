import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/ptvInfoClasses/RouteTypeInfo.dart';
import 'ptv_api_service.dart';
import 'selections.dart';


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
      print("Screen: $_screenName");
    }
  }

  // Fetches Routes and generates Map/Dictionary of PT Options               // I dont like how this logic is in the same file as the frontend rendering, find a way to split this
  Future<void> fetchRouteTypes() async {
    // Fetching Data and converting to JSON
    Data data = await PtvApiService().routeTypes();
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit     // Make it display on screen if there is no data
    if (data.response == null) {print("NULL DATA RESPONSE --> Improper Location Data"); return;}

    // Populating RouteTypes List                                                         // add case for if 0
    for (var entry in jsonResponse!["route_types"]) {
      String name = entry["route_type_name"];
      String type = entry["route_type"].toString();
      RouteType newRouteType = RouteType(name: name, type: type);

      _routeTypesClass.add(newRouteType);
    }

    setState(() {});
  }

  void setRouteType(int index) {
    widget.userSelections.routeType = _routeTypesClass[index];

    // TestPrint
    if (kDebugMode) {
      print(widget.userSelections);
    }
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
            title: Text(_routeTypesClass[index].name),
            onTap: () {
              setRouteType(index);
              Navigator.pushNamed(context, '/selectLocationScreen');
              },
          );
        },
      ),
    );
  }
}
