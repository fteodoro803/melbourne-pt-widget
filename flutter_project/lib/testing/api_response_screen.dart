import 'package:flutter/material.dart';
import '../ptv_api_service.dart';

class ApiResponseScreen extends StatefulWidget {
  @override
  _ApiResponseScreenState createState() => _ApiResponseScreenState();
}

class _ApiResponseScreenState extends State<ApiResponseScreen> {
  PtvApiService apiService = PtvApiService();

  // Input Values and Responses
  Data response = Data(Uri(), null);    // was previously '' but now null for the conversion from JSON string to raw json
  TextEditingController _routeIdController = TextEditingController();
  TextEditingController _locationIdController = TextEditingController();
  TextEditingController _routeTypeController = TextEditingController();
  TextEditingController _routeTypesController = TextEditingController();
  TextEditingController _stopIdController = TextEditingController();
  TextEditingController _maxResultsController = TextEditingController();
  TextEditingController _maxDistanceController = TextEditingController();
  TextEditingController _directionIdController = TextEditingController();
  TextEditingController _expandController = TextEditingController();



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

  void fetchStops(String location, {String? routeTypes, String? maxResults, String? maxDistance}) async {
    Data responseData = await apiService.stops(location, routeTypes: routeTypes, maxResults: maxResults, maxDistance: maxDistance);
    setState(() {
      response = responseData;
    });
  }

  void fetchDepartures(String routeType, String stopId,
      {String? routeId,
      String? directionId,
      String? maxResults,
      String? expand}) async {
    Data responseData = await apiService.departures(routeType, stopId, routeId: routeId, directionId: directionId, maxResults: maxResults, expand: expand);
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

            Wrap(
              direction: Axis.horizontal,
              spacing: 20,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _routeTypeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Route Type',
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _routeIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Route ID',
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _locationIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Location --> -Latitude,-Longitude',
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _stopIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Stop ID',
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _routeTypesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Route Types --> 1,2,3,4',
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _maxResultsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Results',
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _maxDistanceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Distance',
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _directionIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Direction ID',
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _expandController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Expand --> All,None,Disruption',
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // BUTTONS
            Wrap(
              direction: Axis.horizontal,
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
                    fetchStops(_locationIdController.text, routeTypes: _routeTypesController.text, maxResults: _maxResultsController.text, maxDistance: _maxDistanceController.text);
                  },
                  child: Text('Fetch Stops'),
                ),
                ElevatedButton(
                  onPressed: () {
                    fetchDepartures(_routeTypeController.text, _stopIdController.text, routeId: _routeIdController.text, directionId: _directionIdController.text, maxResults: _maxResultsController.text, expand: _expandController.text);
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
                  response.toString(),
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