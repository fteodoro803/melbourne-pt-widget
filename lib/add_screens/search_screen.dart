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
import '../ptv_info_classes/departure_info.dart';
import '../ptv_info_classes/route_direction_info.dart';
import '../ptv_info_classes/stop_info.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/screen_widgets.dart';
import 'departure_details_sheet.dart';
import 'nearby_stops_sheet.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../ptv_info_classes/route_info.dart' as pt_route;
import 'package:flutter_project/google_service.dart';
import 'suggestions_search.dart';

enum ActiveSheet { none, nearbyStops, stopDetails, transportDetails, departureDetails }

class SearchScreen extends StatefulWidget {
  final ScreenArguments arguments;
  const SearchScreen({super.key, required this.arguments});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final String _screenName = "SelectLocation";

  bool _isSheetFullyExpanded = false;
  final DraggableScrollableController _controller = DraggableScrollableController();

  bool _hasDroppedPin = false;

  late Departure _departure;

  DevTools tools = DevTools();
  PtvService ptvService = PtvService();
  GoogleService googleService = GoogleService();
  TransportPathUtils transportPathUtils = TransportPathUtils();

  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  late LatLng _stopPosition;
  late LatLng _stopPositionAlongGeopath;
  late List<LatLng> _geopath = [];
  late List<Stop> _stops = [];
  List<LatLng> _stopsAlongGeopath = [];

  final DraggableScrollableController _controller = DraggableScrollableController();

  final LatLng _initialPosition = const LatLng(-37.813812122509205,
      144.96358311072478); // Change based on user's location

  ActiveSheet _activeSheet = ActiveSheet.none;
  Map<ActiveSheet, double> _sheetScrollPositions = {};
  List<ActiveSheet> _navigationHistory = [];

  // Store NearbyStopsSheet specific state
  final GlobalKey<NearbyStopsSheetState> _nearbyStopsSheetKey = GlobalKey<NearbyStopsSheetState>();
  NearbyStopsState? _savedNearbyStopsState;


  // Initialises the state
  @override
  void initState() {
    super.initState();

    // Listen for changes in the sheet's size

    _controller.addListener(() {
      if (_controller.size > 0.95) {
        if (!_isSheetFullyExpanded) {
          setState(() {
            _isSheetFullyExpanded = true;
            widget.arguments.searchDetails!.isSheetExpanded = true;
          });
        }
      } else if (_controller.size < 0.65) {
        if (_isSheetFullyExpanded) {
          setState(() {
            _isSheetFullyExpanded = false;
            widget.arguments.searchDetails!.isSheetExpanded = false;
          });
        }
      }
    });

    // Debug Printing
    widget.arguments.searchDetails?.distance = 300;
    widget.arguments.searchDetails?.transportType = "all";
    tools.printScreenState(_screenName, widget.arguments);

  }

  // Method to handle sheet transitions
  void _changeSheet(ActiveSheet newSheet, bool newMarker) {
    // Save current sheet's scroll position if controller is attached
    if (_controller.isAttached && _activeSheet != ActiveSheet.none) {
      _sheetScrollPositions[_activeSheet] = _controller.size;

      // Save NearbyStopsSheet state if that's the current sheet
      if (_activeSheet == ActiveSheet.nearbyStops) {
          _savedNearbyStopsState = _getNearbyStopsState();
      }
    }

    // Add to navigation history
    if (_activeSheet != ActiveSheet.none) {
      if (!_navigationHistory.contains(_activeSheet)) {
        _navigationHistory.add(_activeSheet);
      }
    }

    setState(() {
      _activeSheet = newSheet;

      // Restore scroll position
      if (_controller.isAttached) {
        double targetSize = _sheetScrollPositions[newSheet] ?? 0.3;
        _controller.animateTo(
          targetSize,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  NearbyStopsState? _getNearbyStopsState() {
    if (_nearbyStopsSheetKey.currentState != null) {
      return _nearbyStopsSheetKey.currentState!.getCurrentState();
    }
    return null;
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

    // Update the state with the new address
    widget.arguments.searchDetails!.markerPosition = position;
    widget.arguments.searchDetails!.locationController.text = address;
    widget.arguments.searchDetails!.distance = 300;
    widget.arguments.searchDetails!.transportType = "all";
    _hasDroppedPin = true;

  }

  // Retrieves address from coordinates of dropped pin
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
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

  Future<List<Transport>> splitDirection(Stop stop, pt_route.Route route) async {
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
    LatLng stopPos = LatLng(widget.arguments.searchDetails!.stop!.latitude!, widget.arguments.searchDetails!.stop!.longitude!);
    _stopPosition = stopPos;
    _stopPositionAlongGeopath = _stopPosition;

    List<LatLng> geoPathList = await ptvService.fetchGeoPath(widget.arguments.searchDetails!.route!);
    _geopath = geoPathList;
    // List<Stop> stopList = await ptvService.fetchStopsAlongDirection(widget.arguments.searchDetails!.route!, widget.arguments.searchDetails!.route!.direction!);
    List<Stop> stopList = await ptvService.fetchStopsRoute(widget.arguments.searchDetails!.route!);
    _stops = stopList;
    GeopathAndStops geoStops = await transportPathUtils.addStopsToGeoPath(_stops, _geopath, _stopPosition);
    GeopathAndStops geopathAndStops = geoStops;

    _geopath = geopathAndStops.geopath;
    _stopsAlongGeopath = geopathAndStops.stopsAlongGeopath;
    _stopPositionAlongGeopath = geopathAndStops.stopPositionAlongGeopath;

    bool isReverseDirection = GeoPathUtils.reverseDirection(_geopath, _stops);

    _markers = await transportPathUtils.setMarkers(
        _markers,
        _stopsAlongGeopath,
        _stopPositionAlongGeopath,
        isDirectionSpecified,
        isReverseDirection
    );
    _polylines = await transportPathUtils.loadRoutePolyline(
        widget.arguments.searchDetails!.directions[0],
        _geopath,
        _stopPositionAlongGeopath,
        isDirectionSpecified,
        isReverseDirection
    );

    setState(() {
    });
  }

  // Handling choosing a new transport type in ToggleButtonsRow
  void _onSearchFiltersChanged({String? newTransportType, int? newDistance}) {
    String transportType = newTransportType ?? widget.arguments.searchDetails!.transportType;
    int distance = newDistance ?? widget.arguments.searchDetails!.distance;

    _getStops(widget.arguments.searchDetails!.markerPosition!, transportType, distance);

    widget.arguments.searchDetails!.distance = distance;
    widget.arguments.searchDetails!.transportType = transportType;

  }

  // Handling tap on an item in NearbyStopsSheet
  Future<void> _onStopTapped(Stop stop, pt_route.Route route) async {
    List<Transport> listTransport = await splitDirection(stop, route);

    widget.arguments.searchDetails!.stop = stop;
    widget.arguments.searchDetails!.route = route;

    widget.arguments.searchDetails!.directions.clear();
    for (var transport in listTransport) {
      widget.arguments.searchDetails!.directions.add(transport);
    }

    loadTransportPath(false);
    _changeSheet(ActiveSheet.stopDetails, false);
  }

  void _onTransportTapped(Transport transport) {
    widget.arguments.transport = transport;

    loadTransportPath(true);
    _changeSheet(ActiveSheet.transportDetails, false);
  }

  void _onDepartureTapped(Departure departure) {
    _departure = departure;
    _changeSheet(ActiveSheet.departureDetails, false);
  }

  Future<void> _getStops(LatLng position, String transportType, int distance) async {
    StopRouteLists stopRouteLists;

    if (transportType == "all") {
      stopRouteLists = await ptvService.fetchStopRoutePairs(
        position,
        maxDistance: distance,
        maxResults: 50,
      );
    } else {
      stopRouteLists = await ptvService.fetchStopRoutePairs(
        position,
        routeTypes: transportType,
        maxDistance: distance,
        maxResults: 50,
      );
    }

    Set<String> uniqueStopIDs = {};
    List<Stop> uniqueStops = [];

    List<Stop> stopList = stopRouteLists.stops;
    List<pt_route.Route> routeList = stopRouteLists.routes;

    int stopIndex = 0;

    for (var stop in stopList) {
      if (!uniqueStopIDs.contains(stop.id)) {
        // Create a new stop object to avoid reference issues
        Stop newStop = Stop(
          id: stop.id,
          name: stop.name,
          latitude: stop.latitude,
          longitude: stop.longitude,
          distance: stop.distance,
        );

        newStop.routes = <pt_route.Route>[];
        newStop.routeType = routeList[stopIndex].type;

        uniqueStops.add(newStop);
        uniqueStopIDs.add(stop.id);
      }

      // Find the index of this stop in our uniqueStops list
      int uniqueStopIndex = uniqueStops.indexWhere((s) => s.id == stop.id);
      if (uniqueStopIndex != -1) {
        uniqueStops[uniqueStopIndex].routes!.add(routeList[stopIndex]);
      }

      stopIndex++;
    }

    setState(() {
      widget.arguments.searchDetails!.stops = uniqueStops;
    });
  }

  // Sets the map's Marker and Camera to the Location
  Future<void> _onLocationSelected(LatLng selectedLocation) async {
    await setMarker(selectedLocation);

    _getStops(selectedLocation, "all", 300);

    setState(() {
      _polylines.clear();
    });

    mapController.animateCamera(
      CameraUpdate.newLatLng(selectedLocation),
    );

    // Bring the user to the NearbyStopsSheet with the updated data
    _changeSheet(ActiveSheet.nearbyStops, true);
  }

  // Back button handler
  void _handleBackButton() {
    ActiveSheet previousSheet;

    switch (_activeSheet) {
      case ActiveSheet.departureDetails:
        if (_navigationHistory[_navigationHistory.length - 2] == ActiveSheet.transportDetails) {
          previousSheet = ActiveSheet.transportDetails;
        }
        else {previousSheet = ActiveSheet.stopDetails;}
        break;
      case ActiveSheet.transportDetails:
        previousSheet = ActiveSheet.stopDetails;
        // Restore transport path display
        loadTransportPath(false);
        break;
      case ActiveSheet.stopDetails:
        previousSheet = ActiveSheet.nearbyStops;
        // Clear polylines and restore marker
        _polylines.clear();
        setMarker(widget.arguments.searchDetails!.markerPosition!);
        break;
      case ActiveSheet.nearbyStops:
      case ActiveSheet.none:
      default:
        Navigator.pop(context);
        return; // Exit early
    }

    // Remove current sheet from history
    if (_navigationHistory.isNotEmpty &&
        _navigationHistory.last == _activeSheet) {
      _navigationHistory.removeLast();
    }

    // If we need to go back more than one step (e.g., departure → nearby)
    if (_navigationHistory.isNotEmpty &&
        previousSheet != _navigationHistory.last &&
        _navigationHistory.contains(previousSheet)) {
      // Find the correct previous sheet in history
      while (_navigationHistory.isNotEmpty &&
          _navigationHistory.last != previousSheet) {
        _navigationHistory.removeLast();
      }
    }

    _changeSheet(previousSheet, false);
  }

  String _getSheetTitle() {
    switch (_activeSheet) {
      case ActiveSheet.stopDetails:
        return "Stop Details";
      case ActiveSheet.transportDetails:
        return "Transport Details";
      case ActiveSheet.departureDetails:
        return "Departure Details";
      case ActiveSheet.nearbyStops:
      default:
        return "Nearby Stops";
    }
  }

  Widget _getSheetContent(ScrollController scrollController) {
    switch (_activeSheet) {
      case ActiveSheet.stopDetails:
        return StopDetailsSheet(
          arguments: widget.arguments,
          scrollController: scrollController,
          onTransportTapped: _onTransportTapped,
          onDepartureTapped: _onDepartureTapped,
        );
      case ActiveSheet.transportDetails:
        return TransportDetailsSheet(
          arguments: widget.arguments,
          scrollController: scrollController,
          onDepartureTapped: _onDepartureTapped,
        );
      case ActiveSheet.departureDetails:
        return DepartureDetailsSheet(
          arguments: widget.arguments,
          scrollController: scrollController,
          departure: _departure,
        );
      case ActiveSheet.nearbyStops:
      default:
        return NearbyStopsSheet(
          key: _nearbyStopsSheetKey,
          arguments: widget.arguments,
          scrollController: scrollController,
          onSearchFiltersChanged: _onSearchFiltersChanged,
          onStopTapped: _onStopTapped,
          initialState: _savedNearbyStopsState,
          onStateChanged: (state) {
            _savedNearbyStopsState = state;
          },
        );
    }
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
              // onCameraMove: (position) {
              //   setState(() {});
              // },
              onMapCreated: _onMapCreated,
              // Creates marker when user presses on screen
              onLongPress: (LatLng position) async {
                await _onLocationSelected(position);
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
              controller: _controller,
              initialChildSize: 0.6,
              minChildSize: 0.15,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: [0.15, 0.6, 1.0],
              expand: true,
              shouldCloseOnMinExtent: false,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: _isSheetFullyExpanded
                      ? Column(
                        children: [
                          SizedBox(height: 50),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _handleBackButton,
                                child: BackButton(),
                              ),
                              SizedBox(width: 10),
                              Text(_getSheetTitle()),
                            ],
                          ),
                          Divider(),
                          Expanded(child: _getSheetContent(scrollController)),
                        ],
                      )
                    : _getSheetContent(scrollController),
                  );
                }
            ),

          Positioned(
            top: 60,
            left: 15,
            right: 15,
            child: _isSheetFullyExpanded
                ? Container() // Hide search bar when sheet is fully expanded
                : Row(
              children: [
                // Back button with updated handler
                GestureDetector(
                  onTap: _handleBackButton,
                  child: BackButtonWidget(),
                ),
                SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: SuggestionsSearch(onLocationSelected: _onLocationSelected),
                ),
              ],
            ),
          )
        ],
      ),
      // Only call updateMainPage when necessary (e.g., when adding a new route)
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1, // Search page is index 1
        updateMainPage: null,
      ),
    );
  }
}
