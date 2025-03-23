import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/stop_directions.dart';
import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/ptv_info_classes/location_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_project/draggable_scrollable_sheet_widget.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../ptv_api_service.dart';
import '../ptv_info_classes/route_direction_info.dart';
import '../ptv_info_classes/route_info.dart' as PTRoute;
import '../ptv_info_classes/route_type_info.dart';
import '../ptv_info_classes/stop_info.dart';
import 'nearby_stops.dart';

class SelectLocationScreen2 extends StatefulWidget {
  const SelectLocationScreen2({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<SelectLocationScreen2> createState() => _SelectLocationScreen2State();
}

class _SelectLocationScreen2State extends State<SelectLocationScreen2> {
  final String _screenName = "SelectLocation";
  final TextEditingController _locationController =
      TextEditingController(); // Placeholder until map api is implemented

  final List<Stop> _stops = [];
  final List<PTRoute.Route> _routes = [];
  final List<RouteDirection> _directions = [];
  final List<RouteType> _routeTypes = [];

  bool _isStopDirectionsVisible = false;
  Stop? _selectedStop;
  PTRoute.Route? _selectedRoute;

  DevTools tools = DevTools();

  // Map
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  final LatLng _initialPosition =
      const LatLng(-37.813812122509205, 144.96358311072478);
  LatLng? currentPosition;

  bool _hasDroppedPin = false;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Adds a marker at the specified position
  Future<void> setMarker(LatLng position) async {
    MarkerId id = MarkerId(position.toString());  // Unique ID based on position
    markers.clear();
    markers.add(Marker(markerId: id, position: position));

    // Get the address for the dropped marker
    String address = await getAddressFromCoordinates(position.latitude, position.longitude);

    // Update the state with the new address
    setState(() {
      _locationController.text = address; // Set the address in the text field
      _hasDroppedPin = true;
    });

    await fetchStops(position);
  }

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
  void _onStopTapped(Stop stop, PTRoute.Route route) {
    setState(() {
      _selectedStop = stop;
      _selectedRoute = route;
      _isStopDirectionsVisible = true;  // Switch to StopDirectionsSheet
      fetchRouteDirections();
    });
  }

  // Initialising State
  @override
  void initState() {
    super.initState();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  void setLocation() {
    Location newLocation = Location(location: _locationController.text);

    // Normalize the location input by removing spaces
    newLocation.location = newLocation.location.replaceAll(' ', '');

    widget.arguments.transport.location = newLocation;
  }

  void setMapLocation() {
    String? latitude = currentPosition?.latitude.toString();
    String? longitude = currentPosition?.longitude.toString();
    String? location = "$latitude,$longitude";

    Location newLocation = Location(location: location);
    widget.arguments.transport.location = newLocation;
  }

  void _onTransportTypeChanged(String newTransportType) {
    setState(() {
      widget.arguments.transportType = newTransportType;
    });
    _fetchStopsForTransportType();
  }

  Future<void> fetchStops(LatLng position) async {
    String location = "${position.latitude},${position.longitude}";
    if (location.isEmpty) {
      print("Location is empty, unable to fetch stops.");
      return;
    }

    String maxDistance = "300"; // Default to "300" if null

    try {
      // Fetch stops from the API
      ApiData data = await PtvApiService().stops(location, routeTypes: widget.arguments.transportType, maxDistance: maxDistance);
      Map<String, dynamic>? jsonResponse = data.response;

      if (jsonResponse == null) {
        print("NULL DATA RESPONSE --> Improper Location Data");
        return;
      }
      print("DATA RESPONSE PENDING");
      print("ROUTE TYPE: ${widget.arguments.transportType}");

      // Clear previous stops and routes
      _stops.clear();
      _routes.clear();

      // Iterate over the stops and routes to populate them
      for (var stop in jsonResponse["stops"]) {
        for (var route in stop["routes"]) {
          if (route["route_type"].toString() != widget.arguments.transportType && widget.arguments.transportType != "all") {
            continue;
          }
          String stopId = stop["stop_id"].toString();
          String stopName = stop["stop_name"];
          Stop newStop = Stop(id: stopId, name: stopName);

          String routeName = route["route_name"];
          String routeNumber = route["route_number"].toString();
          String routeId = route["route_id"].toString();
          PTRoute.Route newRoute = PTRoute.Route(name: routeName, number: routeNumber, id: routeId);

          // newRoute.getRouteColour(widget.arguments.transport.routeType!.name);

          _stops.add(newStop);
          _routes.add(newRoute);
        }
      }

      // Call setState() to refresh the UI
      setState(() {});
    } catch (e) {
      // Handle any errors that might occur during the fetch
      print("Error fetching stops: $e");
    }
  }

  void fetchRouteDirections() async {
    String? routeId =
        _selectedRoute?.id;

    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeDirections(routeId!);
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit
    if (data.response == null) {
      print("NULL DATA RESPONSE --> Improper Location Data");
      return;
    }

    // Populating Stops List
    for (var direction in jsonResponse!["directions"]) {
      // if (direction["route_id"] != widget.userSelections.stop?.route.id) {continue;}

      String id = direction["direction_id"].toString();
      String name = direction["direction_name"];
      String description = direction["route_direction_description"];
      RouteDirection newDirection =
      RouteDirection(id: id, name: name, description: description);

      _directions.add(newDirection);
    }

    setState(() {});
  }

  Future<void> _fetchStopsForTransportType() async {
    if (currentPosition != null) {
      await fetchStops(currentPosition!);
    }
  }

  // Fetches Routes and generates Map/Dictionary of PT Options               // I dont like how this logic is in the same file as the frontend rendering, find a way to split this
  Future<void> fetchRouteTypes() async {
    // Fetching Data and converting to JSON
    ApiData data = await PtvApiService().routeTypes();
    Map<String, dynamic>? jsonResponse = data.response;

    // Early Exit     // Make it display on screen if there is no data
    if (data.response == null) {
      print("NULL DATA RESPONSE --> Improper Location Data");
      return;
    }

    // Populating RouteTypes List                                                         // add case for if 0
    for (var entry in jsonResponse!["route_types"]) {
      String name = entry["route_type_name"];
      String type = entry["route_type"].toString();
      RouteType newRouteType = RouteType(name: name, type: type);

      _routeTypes.add(newRouteType);
    }

    setState(() {});
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
              setState(() {
                currentPosition = position.target;
              });
            },
            onMapCreated: _onMapCreated,
            onLongPress: (LatLng position) {
              if (!_isStopDirectionsVisible) {  // Only create marker if StopDirectionsSheet is not visible
                setState(() {
                  setMarker(position);  // Drop marker on long press
                });
                widget.arguments.markerPosition = position; // Store the marker position
              }
            },
            initialCameraPosition: CameraPosition(
                target: _initialPosition, zoom: 15), // No initial marker
            markers: markers,
          ),
        ),
        if (_hasDroppedPin)
          DraggableScrollableSheetWidget(
            scrollController: ScrollController(),
            child: _isStopDirectionsVisible
                ? StopDirectionsSheet(
              scrollController: ScrollController(),
              route: _selectedRoute!,
              stop: _selectedStop!,
              directions: _directions,
              arguments: widget.arguments,
            )
                : NearbyStopsSheet(
              scrollController: ScrollController(),
              locationController: _locationController,
              arguments: widget.arguments,
              stops: _stops,
              routes: _routes,
              onTransportTypeChanged: _onTransportTypeChanged,
              onStopTapped: _onStopTapped,
            ),
          ),

        Positioned(
          top: 40,
          left: 15,
          right: 15,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // If we're on the StopDirectionsSheet, go back to NearbyStopsSheet
                    if (_isStopDirectionsVisible) {
                      setState(() {
                        _isStopDirectionsVisible = false;  // Go back to NearbyStopsSheet
                      });
                    } else {
                      // Default back navigation behavior if not on StopDirectionsSheet
                      Navigator.pop(context);
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

                // Conditionally hide the search bar if `_isStopDirectionsVisible` is true
                if (!_isStopDirectionsVisible) ...[
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
                        );
                      },
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
