import 'dart:math';

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
  bool _showStops = false;

  late Departure _departure;

  DevTools tools = DevTools();
  PtvService ptvService = PtvService();
  GoogleService googleService = GoogleService();
  TransportPathUtils transportPathUtils = TransportPathUtils();

  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};

  late LatLng _stopPosition;
  late LatLng _stopPositionAlongGeopath;
  late List<LatLng> _geopath = [];
  late List<Stop> _stops = [];
  List<LatLng> _stopsAlongGeopath = [];

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
      if (_controller.size >= 0.85) {
        if (!_isSheetFullyExpanded) {
          setState(() {
            _controller.jumpTo(1.0);
            _isSheetFullyExpanded = true;
            widget.arguments.searchDetails!.isSheetExpanded = true;
          });
        }
      } else if (_controller.size < 0.85) {
        if (_isSheetFullyExpanded) {
          setState(() {
            _controller.jumpTo(0.6);
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
    if (_activeSheet != ActiveSheet.none && !newMarker) {
      _navigationHistory.add(_activeSheet);
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
  void setMarker(LatLng position) {
    MarkerId id = MarkerId(position.toString()); // Unique ID based on position
    _markers.clear();
    _markers.add(Marker(
        markerId: id,
        position: position,
    ));
  }

  Future <void> showStopMarkers() async {
    if (_showStops) {
      setMarker(widget.arguments.searchDetails!.markerPosition!);
      BitmapDescriptor? customMarkerIconTrain = await transportPathUtils.getResizedImage("assets/icons/PTV train Logo.png", 20, 20);
      BitmapDescriptor? customMarkerIconTram = await transportPathUtils.getResizedImage("assets/icons/PTV tram Logo.png", 20, 20);
      BitmapDescriptor? customMarkerIconBus = await transportPathUtils.getResizedImage("assets/icons/PTV bus Logo.png", 20, 20);
      BitmapDescriptor? customMarkerIconVLine = await transportPathUtils.getResizedImage("assets/icons/PTV vLine Logo.png", 20, 20);

      setState(() {
        for (var stop in widget.arguments.searchDetails!.stops) {
          LatLng stopPosition = LatLng(stop.latitude!, stop.longitude!);
          BitmapDescriptor? customMarkerIcon;
          if (stop.routeType?.type.name == "tram") {
            customMarkerIcon = customMarkerIconTram;
          }
          if (stop.routeType?.type.name == "train") {
            customMarkerIcon = customMarkerIconTrain;
          }
          if (stop.routeType?.type.name == "bus") {
            customMarkerIcon = customMarkerIconBus;
          }
          if (stop.routeType?.type.name == "vLine") {
            customMarkerIcon = customMarkerIconVLine;
          }
          _markers.add(
            Marker(
              markerId: MarkerId(stop.name),
              position: stopPosition,
              icon: customMarkerIcon!,
              // anchor: const Offset(0.5, 0.5),
              onTap: () {
                setState(() {
                  for (var s in widget.arguments.searchDetails!.stops) {
                    s.isExpanded = false;
                  }
                  stop.isExpanded = true;
                });

              }
            )
          );
        }
        _circles.clear();
        _circles.add(
            Circle(
              circleId: CircleId("circle"),
              center: widget.arguments.searchDetails!.markerPosition!,
              fillColor: Colors.blue.withOpacity(0.2),
              strokeWidth: 0,
              radius: widget.arguments.searchDetails!.distance.toDouble(),
            )
        );
      });
    }
    else {
      _circles.clear();
      setMarker(widget.arguments.searchDetails!.markerPosition!);
    }
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
    String? routeId = route.id.toString();
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
      int id = direction["direction_id"];
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

    // Early exit if GeoPath is empty
    if (geoPathList.isEmpty) {
      return;
    }

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
  Future<void> _onSearchFiltersChanged({String? newTransportType, int? newDistance}) async {
    String transportType = newTransportType ?? widget.arguments.searchDetails!.transportType;
    int oldDistance = widget.arguments.searchDetails!.distance;
    int distance = newDistance ?? oldDistance;

    await _getStops(widget.arguments.searchDetails!.markerPosition!, transportType, distance);

    LatLngBounds bounds = await _calculateBoundsForMarkers(distance.toDouble());

    // todo: when the camera reanimates, make it center properly on the pin again (at 0.7x the height of the screen)
    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // Padding around the bounds (50 is arbitrary)
    );

    widget.arguments.searchDetails!.distance = distance;
    widget.arguments.searchDetails!.transportType = transportType;
    await showStopMarkers();

  }

  // Function to calculate the bounds that include all points within a given distance from _chosenPosition
  Future<LatLngBounds> _calculateBoundsForMarkers(double distanceInMeters) async {
    List<LatLng> allPoints = [];
    LatLng chosenPosition = widget.arguments.searchDetails!.markerPosition!;

    // Add the chosen position as the center point
    allPoints.add(chosenPosition);

    double latMin = chosenPosition.latitude;
    double latMax = chosenPosition.latitude;
    double lonMin = chosenPosition.longitude;
    double lonMax = chosenPosition.longitude;

    for (LatLng point in allPoints) {
      double latDelta = point.latitude - chosenPosition.latitude;
      double lonDelta = point.longitude - chosenPosition.longitude;

      if (latDelta < latMin) latMin = point.latitude;
      if (latDelta > latMax) latMax = point.latitude;

      if (lonDelta < lonMin) lonMin = point.longitude;
      if (lonDelta > lonMax) lonMax = point.longitude;
    }

    // Adjusting bounds to cover the given distance
    double latDistance = distanceInMeters / 111000; // 111000 meters = 1 degree of latitude
    double lonDistance = distanceInMeters / (111000 * cos(chosenPosition.latitude * pi / 180));

    latMin -= latDistance;
    latMax += latDistance;
    lonMin -= lonDistance;
    lonMax += lonDistance;

    // Return the calculated bounds
    return LatLngBounds(
      southwest: LatLng(latMin, lonMin),
      northeast: LatLng(latMax, lonMax),
    );
  }

  // Handling tap on an item in NearbyStopsSheet
  Future<void> _onStopTapped(Stop stop, pt_route.Route route) async {
    // _showStops = false;
    _circles.clear();
    setMarker(widget.arguments.searchDetails!.markerPosition!);
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

  void _onDepartureTapped(Departure departure, Transport transport) {
    widget.arguments.transport = transport;
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
      if (!uniqueStopIDs.contains(stop.id.toString())) {
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
        uniqueStopIDs.add(stop.id.toString());
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
    _circles.clear();
    _polylines.clear();

    // Get the address for the dropped marker
    String address =
    await getAddressFromCoordinates(selectedLocation.latitude, selectedLocation.longitude);
    await _getStops(selectedLocation, "all", 300);

    // Update the state with the new address
    widget.arguments.searchDetails!.markerPosition = selectedLocation;
    widget.arguments.searchDetails!.locationController.text = address;
    widget.arguments.searchDetails!.distance = 300;
    widget.arguments.searchDetails!.transportType = "all";
    _hasDroppedPin = true;


    // Get the current map's zoom level and visible region
    LatLngBounds visibleRegion = await mapController.getVisibleRegion();

    // Calculate the height of the visible region in latitude degrees
    double latitudeSpan = visibleRegion.northeast.latitude - visibleRegion.southwest.latitude;

    // Calculate 70% from the top of the screen in latitude degrees
    // Positive offset moves down from center (center is at 50%)
    double verticalOffsetFactor = 0.15; // 70% from top = 20% from center upward = -0.4 from center
    double latitudeOffset = latitudeSpan * verticalOffsetFactor;

    // Create new camera position with adjusted latitude
    CameraPosition newCameraPosition = CameraPosition(
      target: LatLng(
          selectedLocation.latitude - latitudeOffset, // Move upward from the marker
          selectedLocation.longitude // Keep longitude the same for horizontal centering
      ),
      zoom: 16,
    );

    // Animate the camera to this position
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(newCameraPosition),
    );

    // Bring the user to the NearbyStopsSheet with the updated data
    _changeSheet(ActiveSheet.nearbyStops, true); //todo: FIX ISSUE WHERE SEARCH FILTERS ARE STILL THE SAME BETWEEN DROPPED PINS

    showStopMarkers();
  }

  void _handleBackButton() {
    ActiveSheet previousSheet;

    // Handle different scenarios depending on the current active sheet
    switch (_activeSheet) {
      case ActiveSheet.departureDetails:
      // Check if the last visited sheet was transportDetails
        if (_navigationHistory.isNotEmpty && _navigationHistory.last == ActiveSheet.transportDetails) {
          previousSheet = ActiveSheet.transportDetails;
        } else {
          previousSheet = ActiveSheet.stopDetails;
        }
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
        showStopMarkers();
        break;

      case ActiveSheet.nearbyStops:
        if (_isSheetFullyExpanded) {
          _controller.jumpTo(0.6);
          return;
        }
        previousSheet = ActiveSheet.none;
        _hasDroppedPin = false;
        _markers.clear();
        _circles.clear();
        break;

      default:
        Navigator.pop(context);
        return;
    }

    // Remove the current sheet from history if it matches the last one
    if (_navigationHistory.isNotEmpty && _navigationHistory.last == _activeSheet) {
      _navigationHistory.removeLast();
    }

    // Handle the case where we might have skipped sheets (e.g., direct transition to departureDetails)
    if (_navigationHistory.isNotEmpty &&
        previousSheet != _navigationHistory.last &&
        _navigationHistory.contains(previousSheet)) {
      // Clean up history by removing any sheets that are not in the path
      while (_navigationHistory.isNotEmpty && _navigationHistory.last != previousSheet) {
        _navigationHistory.removeLast();
      }
    }

    // Perform the sheet change
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
              circles: _circles,
            ),
          ),

          // Create DraggableScrollableSheet with nearby stop information if user has dropped pin
          if (_hasDroppedPin)
            DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: 0.6,
              minChildSize: 0.15,
              maxChildSize: 1.0,
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
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new),
                                onPressed: () => _handleBackButton(),
                              ),
                              Expanded(
                                child: Text(
                                  _getSheetTitle(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.location_pin),
                                onPressed: () => _controller.jumpTo(0.6),
                              ),
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

          _isSheetFullyExpanded
            ? Container() // Hide search bar when sheet is fully expanded
            : Column(
              children: [
                SizedBox(height: 60),
                Row(
                  children: [
                    // Back button with updated handler
                    SizedBox(width: 18),
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
                if (_activeSheet == ActiveSheet.nearbyStops)
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _showStops = !_showStops;
                      });
                      await showStopMarkers();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: !_showStops ?
                        Theme.of(context).colorScheme.surfaceContainerHighest :
                        Theme.of(context).colorScheme.primaryContainer,
                      minimumSize: Size(40, 40),
                      ),
                    child: SizedBox(
                      height: 40,
                      width: 40,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_pin),
                            Icon(Icons.tram),
                          ],
                        ),
                      ),
                    )

                  ),
              ],
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
