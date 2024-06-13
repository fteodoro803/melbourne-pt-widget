import 'package:flutter/material.dart';
import 'ptv_api_service.dart'; // Update with your actual import path

class ApiResponseScreen extends StatefulWidget {
  @override
  _ApiResponseScreenState createState() => _ApiResponseScreenState();
}

class _ApiResponseScreenState extends State<ApiResponseScreen> {
  PtvApiService apiService = PtvApiService();

  // Input Values and Responses
  Data response = Data(Uri(), '');
  TextEditingController _routeIdController = TextEditingController();
  TextEditingController _locationIdController = TextEditingController();
  TextEditingController _routeTypeController = TextEditingController();
  TextEditingController _stopIdController = TextEditingController();


  void fetchRouteTypes() async {
    Data responseData = await apiService.routeTypes();
    setState(() {
      response = responseData;
    });
  }

  void fetchRouteDirections(String routeId) async {
    Data responseData = await apiService.routeDirections(routeId);
    setState(() {
      response = responseData;
    });
  }

  void fetchStops(String location) async {
    Data responseData = await apiService.stops(location);
    setState(() {
      response = responseData;
    });
  }

  void fetchDepartures(String routeType, String stopId, String? routeId) async {
    Data responseData = await apiService.departures(routeType, stopId, routeId);
    setState(() {
      response = responseData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Response Viewer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TEXT FIELDS
            TextField(
              controller: _routeTypeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Route Type',
              ),
            ),
            TextField(
              controller: _routeIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Route ID',
              ),
            ),
            TextField(
              controller: _locationIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Location',
              ),
            ),
            TextField(
              controller: _stopIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Stop',
              ),
            ),

            SizedBox(height: 16),

            // BUTTONS
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    fetchRouteTypes();
                  },
                  child: Text('Fetch Route Types'),
                ),
                ElevatedButton(
                  onPressed: () {
                    fetchRouteDirections(_routeIdController.text);
                  },
                  child: Text('Fetch Route Directions'),
                ),
                ElevatedButton(
                  onPressed: () {
                    fetchStops(_locationIdController.text);
                  },
                  child: Text('Fetch Stops'),
                ),
                ElevatedButton(
                  onPressed: () {
                    fetchDepartures(_routeTypeController.text, _stopIdController.text, _routeIdController.text);
                  },
                  child: Text('Fetch Departures'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(response.url.toString()),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  response.response,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}