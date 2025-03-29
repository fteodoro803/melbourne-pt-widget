import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/stop_details_sheet.dart';
import 'package:flutter_project/add_screens/transport_details_sheet.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api_data.dart';
import '../geopath_utils.dart';
import '../ptv_api_service.dart';
import '../ptv_info_classes/route_direction_info.dart';
import '../ptv_info_classes/stop_info.dart';
import 'nearby_stops_sheet.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../ptv_info_classes/route_info.dart' as PTRoute;
import 'package:flutter_project/google_service.dart';
import 'suggestions_search.dart';

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
  bool _isTransportSelected = false;

  DevTools tools = DevTools();
  PtvService ptvService = PtvService();
  GoogleService googleService = GoogleService();
  TransportPathUtils transportPathUtils = TransportPathUtils();

// Map
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  late LatLng _stopPosition;
  late LatLng _stopPositionAlongGeopath;
  late List<LatLng> _geopath = [];
  late List<Stop> _stops = [];
  List<LatLng> _stopsAlongGeopath = [];

  final LatLng _initialPosition = const LatLng(-37.813812122509205,
      144.96358311072478); // Change based on user's location

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
    MarkerId id = MarkerId(position.toString()); // Unique ID based on position
    _markers.clear();
    _markers.add(Marker(markerId: id, position: position));

    // Get the address for the dropped marker
    String address =
        await getAddressFromCoordinates(position.latitude, position.longitude);
    StopRouteLists stopRouteLists = await ptvService
        .fetchStopRoutePairs(widget.arguments.searchDetails.markerPosition!);
    // widget.arguments.searchDetails.routes = stopRouteLists.routes;
    // widget.arguments.searchDetails.stops = stopRouteLists.stops;

    // Update the state with the new address
    setState(() {
      widget.arguments.searchDetails.markerPosition = position;
      widget.arguments.searchDetails.routes = stopRouteLists.routes;
      widget.arguments.searchDetails.stops = stopRouteLists.stops;
      widget.arguments.searchDetails.locationController.text =
          address; // Set the address in the text field
      _hasDroppedPin = true;
    });
  }

  // Retrieves address from coordinates of dropped pin
  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(latitude, longitude);
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

    for (var direction in directions) {
      Transport newTransport = Transport.withStopRoute(stop, route, direction);
      newTransport.routeType = RouteType.withId(id: route.type.type.id);
      await newTransport.updateDepartures();
      transportList.add(newTransport);
    }

    return transportList;
  }

  Future<void> loadTransportPath(bool isDirectionSpecified) async {
    _stopPosition = LatLng(widget.arguments.searchDetails.stop!.latitude!, widget.arguments.searchDetails.stop!.longitude!);
    _stopPositionAlongGeopath = _stopPosition;

    _geopath = await ptvService.fetchGeoPath(widget.arguments.searchDetails.route!);
    _stops = await ptvService.fetchStopsAlongDirection(widget.arguments.searchDetails.route!, widget.arguments.transport.direction!);
    GeopathAndStops geopathAndStops = await transportPathUtils.addStopsToGeoPath(_stops, _geopath, _stopPosition);

    _geopath = geopathAndStops.geopath;
    _stopsAlongGeopath = geopathAndStops.stopsAlongGeopath;
    _stopPositionAlongGeopath = geopathAndStops.stopPositionAlongGeopath;

    bool isReverseDirection = GeoPathUtils.reverseDirection(_geopath, _stops);

    _markers = await transportPathUtils.setMarkers(
        _stopsAlongGeopath,
        _stopPositionAlongGeopath,
        widget.arguments.searchDetails.markerPosition,
        isDirectionSpecified,
        isReverseDirection);
    _polylines = await transportPathUtils.loadRoutePolyline(
        widget.arguments.searchDetails.directions[0],
        _geopath,
        _stopPositionAlongGeopath,
        isDirectionSpecified,
        isReverseDirection);

    setState(() {
    });
  }

  // Handling choosing a new transport type in ToggleButtonsRow
  void _onTransportTypeChanged(String newTransportType) async {
    StopRouteLists stopRouteLists;
    if (newTransportType == "all") {
      stopRouteLists = await ptvService
          .fetchStopRoutePairs(widget.arguments.searchDetails.markerPosition!);
    } else {
      stopRouteLists = await ptvService.fetchStopRoutePairs(
          widget.arguments.searchDetails.markerPosition!,
          routeTypes: newTransportType);
    }

    setState(() {
      widget.arguments.searchDetails.routes = stopRouteLists.routes;
      widget.arguments.searchDetails.stops = stopRouteLists.stops;
    });
  }

  // Handling tap on an item in NearbyStopsSheet
  Future<void> _onStopTapped(Stop stop, PTRoute.Route route) async {
    List<Transport> listTransport = await splitDirection(stop, route);

    setState(() {
      widget.arguments.searchDetails.stop = stop;
      widget.arguments.searchDetails.route = route;
      _isStopSelected = true; // Switch to StopDirectionsSheet

      widget.arguments.searchDetails.directions.clear();
      for (var transport in listTransport) {
        widget.arguments.searchDetails.directions.add(transport);
      }
    });
    loadTransportPath(false);
  }

  Future<void> _onTransportTapped(Transport transport) async {
    setState(() {
      widget.arguments.transport = transport;
      _isTransportSelected = true;
    });
    loadTransportPath(true);
  }

  // Rendering
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              onCameraMove: (position) {
                setState(() {
                  widget.arguments.mapZoom = position.zoom;
                  widget.arguments.mapCenter = position.target;
                });
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
              initialCameraPosition:
                  CameraPosition(target: _initialPosition, zoom: 15),
              markers: _markers,
              polylines: _polylines,
            ),
          ),

          // Create DraggableScrollableSheet with nearby stop information if user has dropped pin
          if (_hasDroppedPin)
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.2,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          red: 0,
                          green: 0,
                          blue: 0,
                          alpha: 0.1,
                        ),
                        spreadRadius: 1,
                        blurRadius: 7,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _isStopSelected
                      ? _isTransportSelected
                          ? TransportDetailsSheet(
                              arguments: widget.arguments,
                              scrollController: scrollController,
                            )
                          : StopDetailsSheet(
                              arguments: widget.arguments,
                              scrollController: scrollController,
                              onTransportTapped: _onTransportTapped,
                            )
                      : NearbyStopsSheet(
                          arguments: widget.arguments,
                          scrollController: scrollController,
                          onTransportTypeChanged: _onTransportTypeChanged,
                          onStopTapped: _onStopTapped,
                        ),
                );
              },
            ),

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
                      if (_isStopSelected && !_isTransportSelected) {
                        setState(() {
                          _isStopSelected = false; // Return to list of stops
                          _polylines = {};
                          setMarker(widget.arguments.searchDetails.markerPosition!);
                        });
                      } else if (_isTransportSelected) {
                        setState(() {
                          _isTransportSelected =
                              false; // Return to list of stops
                          loadTransportPath(false);
                        });
                      } else {
                        Navigator.pop(context); // Return to home page
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
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
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 30,
                      ),
                    ),
                  ),

                  // Conditionally renders search bar if stop has not been selected
                  if (!_isStopSelected) ...[
                    SizedBox(width: 10),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: SuggestionsSearch(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
