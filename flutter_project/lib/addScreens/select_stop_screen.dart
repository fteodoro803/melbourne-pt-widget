import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import '../ptv_api_service.dart';
import '../ptvInfoClasses/StopInfo.dart';
import '../ptvInfoClasses/RouteInfo.dart' as PTRoute;    // to avoid conflict with material's "Route"

class SelectStopScreen extends StatefulWidget {
  const SelectStopScreen({super.key, required this.transport});

  final Transport transport;

  @override
  State<SelectStopScreen> createState() => _SelectStopScreenState();
}

class _SelectStopScreenState extends State<SelectStopScreen> {
  String _screenName = "SelectStop";
  List<Stop> _stops = [];
  List<PTRoute.Route> _routes = [];

  // Initialising State
  @override
  void initState() {
    super.initState();
    fetchStops();

    // Debug Printing
    if (kDebugMode) {
      print("Screen: $_screenName");
    }
  }

  // Fetch Stops            -- do tests to see if not null
  Future<void> fetchStops() async {
    String? location = widget.transport.location?.location;
    String? routeType = widget.transport.routeType?.type;

    // Fetching Data and converting to JSON
    Data data = await PtvApiService().stops(location!, routeTypes: routeType);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {print("NULL DATA RESPONSE --> Improper Location Data"); return;}

    // Populating Stops List
    for (var stop in jsonResponse!["stops"]) {
      for (var route in stop["routes"]) {
        if (route["route_type"].toString() != widget.transport.routeType!.type) {continue;}

        String stopId = stop["stop_id"].toString();
        String stopName = stop["stop_name"];
        Stop newStop = Stop(id: stopId, name: stopName);

        String routeName = route["route_name"];
        String routeNumber = route["route_number"].toString();
        String routeId = route["route_id"].toString();
        PTRoute.Route newRoute = PTRoute.Route(name: routeName,number: routeNumber, id: routeId);

        _stops.add(newStop);
        _routes.add(newRoute);
      }
    }

    setState(() {});
  }

  void setStopAndRoute(index) {
    widget.transport.stop = _stops[index];
    widget.transport.route = _routes[index];

    // TestPrint
    if (kDebugMode) {
      print(widget.transport);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Stop:"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: ListView.builder(      // old
        itemCount: _stops.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${_stops[index].name}: (${_routes[index].number})"),
            subtitle: Text(_routes[index].name),
            onTap: () {
              setStopAndRoute(index);
              Navigator.pushNamed(context, '/selectDirectionScreen');
            },

          );
        },
      ),
    );
  }
}
