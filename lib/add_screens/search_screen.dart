import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/stop_details_sheet.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api_data.dart';
import '../ptv_api_service.dart';
import '../ptv_info_classes/route_direction_info.dart';
import '../ptv_info_classes/stop_info.dart';
import 'nearby_stops_sheet.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../ptv_info_classes/route_info.dart' as PTRoute;


class SearchScreen extends StatefulWidget {

  final ScreenArguments arguments;
  const SearchScreen({super.key, required this.arguments});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final String _screenName = "SelectLocation";

  bool _isStopSelected = false;
  bool _hasDroppedPin = false;

  DevTools tools = DevTools();
  PtvService ptvService = PtvService();

  // Map
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  final LatLng _initialPosition =
      const LatLng(-37.813812122509205, 144.96358311072478); // Change based on user's location

  // Initialises the state
  @override
  void initState() {
    super.initState();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  // Initializes the map
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Resets markers and creates new marker when pin is dropped by user
  Future<void> setMarker(LatLng position) async {
    MarkerId id = MarkerId(position.toString());  // Unique ID based on position
    markers.clear();
    markers.add(Marker(markerId: id, position: position));

    // Get the address for the dropped marker
    String address = await getAddressFromCoordinates(position.latitude, position.longitude);

    // Update the state with the new address
    setState(() {
      widget.arguments.searchDetails.locationController.text = address; // Set the address in the text field
      _hasDroppedPin = true;
    });

    // TO DO (BACKEND):
    // INPUT: LatLng position, "all", Double range
    // OUTPUT: List<Stop> stops ->
    // DESCRIPTION: list of all stops (regardless of transport type) within some range of marker
    // SAVE TO WIDGET.ARGUMENTS.SEARCHDETAILS.STOPS

    print("MARKER POSITION: ${widget.arguments.searchDetails.markerPosition}");
    StopRouteLists stopRouteLists = await ptvService.fetchStopRoutePairs(widget.arguments.searchDetails.markerPosition!);
    widget.arguments.searchDetails.routes = stopRouteLists.routes;
    widget.arguments.searchDetails.stops = stopRouteLists.stops;
  }

  // Retrieves address from coordinates of dropped pin
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        // Return a string with the address (you can adjust what part of the address you want)
        return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Address not found"; // Return a default message if something goes wrong
  }

  // Handling tap on an item in NearbyStopsSheet
  void _onStopTapped(Stop stop, PTRoute.Route route) async {

    // print("(search_screen.dart -> Stops ) -- ${stop}");
    // print("(search_screen.dart -> Routes ) -- ${route}");

    List<Transport> listTransport = await splitDirection(stop, route);

    print("(search_screen.dart -> _onStopTapped ) -- Transport List: ${listTransport}");
    print("(search_screen.dart -> _onStopTapped ) -- Transport List Length: ${listTransport.length}");
    print("(search_screen.dart -> _onStopTapped) -- Departures1: ${listTransport[0].departures}");
    print("(search_screen.dart -> _onStopTapped) -- Departures2: ${listTransport[1].departures}");


    setState(() {
      widget.arguments.searchDetails.stop = stop;
      widget.arguments.searchDetails.route = route;
      _isStopSelected = true;  // Switch to StopDirectionsSheet
      widget.arguments.searchDetails.directions.add(listTransport[0]);
      widget.arguments.searchDetails.directions.add(listTransport[1]);
      print("(search_screen.dart -> _onStopTapped) -- Transport1: ${widget.arguments.searchDetails.directions[0]}");
      print("(search_screen.dart -> _onStopTapped) -- Transport2: ${widget.arguments.searchDetails.directions[1]}");

      print("(search_screen.dart -> _onStopTapped) -- Departures: ${widget.arguments.searchDetails.directions[0].departures}");
    });

    // TO DO (BACKEND):
    // INPUT: Stop stop, Route route
    // OUTPUT: [Transport transport1, Transport transport2]:
    // DESCRIPTION: Transports for both directions for given stop and route
    // SAVE TO WIDGET.ARGUMENTS.SEARCHDETAILS.DIRECTIONS
  }

  Future<List<Transport>> splitDirection(Stop stop, PTRoute.Route route) async {
    String? routeId = route.id;
    List<RouteDirection> directions = [];
    List<Transport> transportList = [];

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeDirections(routeId);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print(
          "( search_screen.dart -> splitDirection ) -- Null Data response Improper Data");
      return [];
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      String id = direction["direction_id"].toString();
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      RouteDirection newDirection =
      RouteDirection(id: id, name: name, description: description);

      directions.add(newDirection);
    }

    // print("( search_screen.dart -> splitDirection ) -- Direction: ${directions}");

    // New Transports
    Transport transport1 = Transport.withStopRoute(stop, route, directions[0]);
    transport1.routeType = RouteType(name: "Tram", type: "1");
    // print("( search_screen.dart -> splitDirection ) -- Transport1: ${transport1}");
    await transport1.updateDepartures();
    transportList.add(transport1);

    Transport transport2 = Transport.withStopRoute(stop, route, directions[1]);
    transport2.routeType = RouteType(name: "Tram", type: "1");
    await transport2.updateDepartures();
    // print("( search_screen.dart -> splitDirection ) -- Transport2: ${transport2}");
    transportList.add(transport2);

    // print("( search_screen.dart -> splitDirection ) -- Transport List: ${transportList}");

    return transportList;
  }

  // Handling choosing a new transport type in ToggleButtonsRow
  void _onTransportTypeChanged(String newTransportType) async {
    StopRouteLists stopRouteLists = await ptvService.fetchStopRoutePairs(widget.arguments.searchDetails.markerPosition!);


    setState(() {
      widget.arguments.searchDetails.transportType = newTransportType;
      widget.arguments.searchDetails.routes = stopRouteLists.routes;
      widget.arguments.searchDetails.stops = stopRouteLists.stops;
    });

    // fetchStops(widget.arguments.searchDetails.markerPosition, widget.arguments.searchDetails.transportType, 300)
    // TO DO (BACKEND):
    // INPUT: LatLng position, String routeTypeName, Double range -> If routeTypeName is "all", show all stops regardless of transport type
    // OUTPUT: List<Stop,Routes> stopsAndRoutes ->
    // DESCRIPTION: list of stops of a given transport type within some range of marker
    // SAVE TO WIDGET.ARGUMENTS.SEARCHDETAILS.STOPS
    // DONE!!!!

    //    in ptv_service.dart; there is an example in select_stop_screen.dart

  }

  // Rendering
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(children: [

        // Google Map
        Positioned.fill(
          child: GoogleMap(
            onCameraMove: (position) {
              setState(() {});
            },
            onMapCreated: _onMapCreated,
            // Creates marker when user presses on screen
            onLongPress: (LatLng position) {
              if (!_isStopSelected) {
                setState(() {
                  setMarker(position);
                });
                // Sets marker position and transport location
                widget.arguments.searchDetails.markerPosition = position;
              }
            },
            // Set initial position and zoom of map
            initialCameraPosition: CameraPosition(
                target: _initialPosition, zoom: 15
            ),
            markers: markers,
          ),
        ),

        // Create DraggableScrollableSheet with nearby stop information if user has dropped pin
        if (_hasDroppedPin)

          // Show all nearby stops to dropped pin of a given transport type
          if (!_isStopSelected)
            NearbyStopsSheet(
              arguments: widget.arguments,
              onTransportTypeChanged: _onTransportTypeChanged,
              onStopTapped: _onStopTapped,
            ),

        // If user has selected a stop, show the stop details screen instead
        if (_isStopSelected)
            StopDetailsSheet(arguments: widget.arguments),

        // Back button and search bar
        Positioned(
          top: 40,
          left: 15,
          right: 15,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Back button rendering and functionality
                GestureDetector(
                  // Changes back button functionality depending on if stop has been selected
                  onTap: () {
                    if (_isStopSelected) {
                      setState(() {
                        _isStopSelected = false; // Return to list of stops
                      });
                    } else {
                      Navigator.pop(context); // Return to home page
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),

                // Conditionally renders search bar if stop has not been selected
                if (!_isStopSelected) ...[
                  SizedBox(width: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: SearchAnchor(
                      builder: (BuildContext context, SearchController controller) {
                        return SearchBar(
                          controller: controller,
                          padding: const WidgetStatePropertyAll<EdgeInsets>(
                            EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                          onTap: () {
                            controller.openView();
                          },
                          onChanged: (_) {
                            controller.openView();
                          },
                          leading: const Icon(Icons.search),
                          hintText: "Search here",
                        );
                      },
                      // Renders list of suggestions
                      suggestionsBuilder: (BuildContext context, SearchController controller) {
                        return List<ListTile>.generate(5, (int index) {
                          final String item = 'item $index';
                          return ListTile(
                            title: Text(item),
                            onTap: () {
                              setState(() {
                                controller.closeView(item);
                              });
                            },
                          );
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
