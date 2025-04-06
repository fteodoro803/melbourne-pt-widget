import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';

import 'package:flutter_project/add_screens/stop_details_sheet.dart';
import 'package:flutter_project/add_screens/transport_details_sheet.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/google_service.dart';

import '../ptv_info_classes/departure_info.dart';
import '../ptv_info_classes/stop_info.dart';
import '../ptv_info_classes/route_info.dart' as pt_route;

import '../utility/geopath_utils.dart';
import '../utility/map_utils.dart';
import '../utility/search_utils.dart';

import '../widgets/bottom_navigation_bar.dart';
import '../widgets/screen_widgets.dart';

import 'departure_details_sheet.dart';
import 'nearby_stops_sheet.dart';
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

  // DraggableScrollableSheet state management
  final DraggableScrollableController _controller = DraggableScrollableController();
  bool _isSheetFullyExpanded = false;
  bool _hasDroppedPin = false;
  bool _showStops = false;
  ActiveSheet _activeSheet = ActiveSheet.none;
  Map<ActiveSheet, double> _sheetScrollPositions = {};
  List<ActiveSheet> _navigationHistory = [];
  final GlobalKey<NearbyStopsSheetState> _nearbyStopsSheetKey = GlobalKey<NearbyStopsSheetState>();
  NearbyStopsState? _savedNearbyStopsState;

  // Utility
  DevTools tools = DevTools();
  PtvService ptvService = PtvService();
  GoogleService googleService = GoogleService();
  TransportPathUtils transportPathUtils = TransportPathUtils();
  SearchUtils searchUtils = SearchUtils();
  MapUtils mapUtils = MapUtils();

  // Google Map
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
      144.96358311072478); //todo: Change based on user's location
  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController();
  String? _selectedStopId;
  Marker? _selectedStopMarker;


  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

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

    widget.arguments.searchDetails?.distance = 300;
    widget.arguments.searchDetails?.transportType = "all";
    tools.printScreenState(_screenName, widget.arguments);
  }

  NearbyStopsState? _getNearbyStopsState() {
    if (_nearbyStopsSheetKey.currentState != null) {
      return _nearbyStopsSheetKey.currentState!.getCurrentState();
    }
    return null;
  }

  /// Resets markers and creates new marker when pin is dropped by user
  void setMarker(LatLng position) {
    MarkerId id = MarkerId(position.toString()); // Unique ID based on position
    _markers.clear();
    _markers.add(Marker(
        markerId: id,
        position: position,
    ));
  }

  /// Shows nearby stops on map when button is toggled by user
  Future<void> showStopMarkers() async {
    if (_showStops) {
      BitmapDescriptor? customMarkerIconTrain = await transportPathUtils.getResizedImage("assets/icons/PTV train Logo.png", 20, 20);
      BitmapDescriptor? customMarkerIconTram = await transportPathUtils.getResizedImage("assets/icons/PTV tram Logo.png", 20, 20);
      BitmapDescriptor? customMarkerIconBus = await transportPathUtils.getResizedImage("assets/icons/PTV bus Logo.png", 20, 20);
      BitmapDescriptor? customMarkerIconVLine = await transportPathUtils.getResizedImage("assets/icons/PTV vLine Logo.png", 20, 20);

      BitmapDescriptor? customMarkerIconTrainLarge = await transportPathUtils.getResizedImage("assets/icons/PTV train Logo.png", 30, 30);
      BitmapDescriptor? customMarkerIconTramLarge = await transportPathUtils.getResizedImage("assets/icons/PTV tram Logo.png", 30, 30);
      BitmapDescriptor? customMarkerIconBusLarge = await transportPathUtils.getResizedImage("assets/icons/PTV bus Logo.png", 30, 30);
      BitmapDescriptor? customMarkerIconVLineLarge = await transportPathUtils.getResizedImage("assets/icons/PTV vLine Logo.png", 30, 30);

      setState(() {
        setMarker(widget.arguments.searchDetails!.markerPosition!);
        _selectedStopId = null;

        for (var stop in widget.arguments.searchDetails!.stops) {
          BitmapDescriptor? customMarkerIcon;
          BitmapDescriptor? largeCustomMarkerIcon;

          if (stop.routeType?.type.name == "tram") {
            customMarkerIcon = customMarkerIconTram;
            largeCustomMarkerIcon = customMarkerIconTramLarge;
          }
          if (stop.routeType?.type.name == "train") {
            customMarkerIcon = customMarkerIconTrain;
            largeCustomMarkerIcon = customMarkerIconTrainLarge;
          }
          if (stop.routeType?.type.name == "bus") {
            customMarkerIcon = customMarkerIconBus;
            largeCustomMarkerIcon = customMarkerIconBusLarge;
          }
          if (stop.routeType?.type.name == "vLine") {
            customMarkerIcon = customMarkerIconVLine;
            largeCustomMarkerIcon = customMarkerIconVLineLarge;
          }

          LatLng stopPosition = LatLng(stop.latitude!, stop.longitude!);
          _markers.add(
            Marker(
              markerId: MarkerId(stop.id.toString()),
              position: stopPosition,
              icon: customMarkerIcon!,
              consumeTapEvents: true,
                // anchor: const Offset(0.5, 0.5),
              onTap: () {
                // mapController.showMarkerInfoWindow(MarkerId(stop.name));
                setState(() {

                  for (var s in widget.arguments.searchDetails!.stops) {
                    s.isExpanded = false;
                  }
                  stop.isExpanded = true;
                  if (_selectedStopId != null) {
                    _markers.removeWhere((marker) => marker.markerId == MarkerId(_selectedStopId!));
                    _markers.add(_selectedStopMarker!);
                  }
                  _selectedStopMarker = _markers.firstWhere(
                      (marker) => marker.markerId == MarkerId(stop.id.toString()),
                  );
                  _markers.removeWhere((marker) => marker.markerId == MarkerId(stop.name));

                  _selectedStopId = stop.id.toString();
                  _markers.add(Marker(
                    markerId: MarkerId(_selectedStopId!),
                    position: stopPosition,
                    icon: largeCustomMarkerIcon!,
                    ),
                  );

                  _customInfoWindowController.addInfoWindow!(
                    Text(stop.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        shadows: <Shadow>[
                          Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3.0,
                          color: Color.fromARGB(0, 255, 255, 255),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    stopPosition, // Position of the info window
                  );

                  // Find the index of the tapped stop
                  int stopIndex = widget.arguments.searchDetails!.stops.indexOf(stop);

                  // First ensure the sheet is expanded enough to see the content
                  _controller.animateTo(
                    0.4, // Adjust as needed
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );

                  // Scroll to the stop using the global key to access the method
                  // Wait a bit to ensure the expansion is complete
                  Future.delayed(Duration(milliseconds: 100), () {
                    _nearbyStopsSheetKey.currentState?.scrollToStopItem(stopIndex);
                  });
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

  /// Loads route geo path and stops on map
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

  /// Set the map's Marker and Camera to a new marker location
  Future<void> _onLocationSelected(LatLng selectedLocation) async {
    _circles.clear();
    _polylines.clear();

    // Get the address for the dropped marker
    String address =
    await mapUtils.getAddressFromCoordinates(selectedLocation.latitude, selectedLocation.longitude);
    List<Stop> uniqueStops = await searchUtils.getStops(selectedLocation, "all", 300);

    // Update the state with the new address
    widget.arguments.searchDetails!.stops = uniqueStops;
    widget.arguments.searchDetails!.markerPosition = selectedLocation;
    widget.arguments.searchDetails!.locationController.text = address;
    widget.arguments.searchDetails!.distance = 300;
    widget.arguments.searchDetails!.transportType = "all";
    _hasDroppedPin = true;

    _customInfoWindowController.hideInfoWindow!();

    final zoom = await mapController.getZoomLevel();

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: await mapUtils.calculateOffsetPosition(selectedLocation, 0.35, mapController),
          zoom: zoom,
        ),
      ),
    );

    // Bring the user to the NearbyStopsSheet with the updated data
    _changeSheet(ActiveSheet.nearbyStops, true); //todo: FIX ISSUE WHERE SEARCH FILTERS ARE STILL THE SAME BETWEEN DROPPED PINS

    showStopMarkers();
  }

  /// Handles changes in transport type and distance filters on NearbyStopsSheet
  Future<void> _onSearchFiltersChanged({String? newTransportType, int? newDistance}) async {
    String transportType = newTransportType ?? widget.arguments.searchDetails!.transportType;
    int oldDistance = widget.arguments.searchDetails!.distance;
    int distance = newDistance ?? oldDistance;

    List<Stop> uniqueStops = await searchUtils.getStops(widget.arguments.searchDetails!.markerPosition!, transportType, distance);

    if (oldDistance != newDistance && newDistance != null) {
      LatLngBounds bounds = await mapUtils.calculateBoundsForMarkers(distance.toDouble(), widget.arguments.searchDetails!.markerPosition!);

      // First animate to the bounds to ensure all points are visible
      mapController.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );

      // Then adjust the position so the marker is at 70% of height
      await Future.delayed(Duration(milliseconds: 300)); // Wait for first animation to complete

      final LatLng markerPosition = widget.arguments.searchDetails!.markerPosition!;
      final zoom = await mapController.getZoomLevel();

      // Calculate a point that will position our marker at 70% of the map height
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: await mapUtils.calculateOffsetPosition(markerPosition, 0.3, mapController),
            zoom: zoom,
          ),
        ),
      );
    }

    widget.arguments.searchDetails!.stops = uniqueStops;
    widget.arguments.searchDetails!.distance = distance;
    widget.arguments.searchDetails!.transportType = transportType;
    await showStopMarkers();

  }

  /// Handles tap on a route in NearbyStopsSheet
  Future<void> _onStopTapped(Stop stop, pt_route.Route route) async {
    // _showStops = false;
    _circles.clear();
    setMarker(widget.arguments.searchDetails!.markerPosition!);
    List<Transport> listTransport = await searchUtils.splitDirection(stop, route);

    widget.arguments.searchDetails!.stop = stop;
    widget.arguments.searchDetails!.route = route;

    widget.arguments.searchDetails!.directions.clear();
    for (var transport in listTransport) {
      widget.arguments.searchDetails!.directions.add(transport);
    }

    loadTransportPath(false);
    _changeSheet(ActiveSheet.stopDetails, false);
    _customInfoWindowController.hideInfoWindow!();
  }

  /// Handles tap on a direction in StopDetailsSheet
  void _onTransportTapped(Transport transport) {
    widget.arguments.transport = transport;

    loadTransportPath(true);
    _changeSheet(ActiveSheet.transportDetails, false);
  }

  /// Handles tap on a departure in StopDetailsSheet and TransportDetailsSheet
  void _onDepartureTapped(Departure departure, Transport transport) {
    widget.arguments.transport = transport;
    widget.arguments.searchDetails!.departure = departure;
    if (_activeSheet == ActiveSheet.stopDetails) {
      loadTransportPath(true);
    }
    _changeSheet(ActiveSheet.departureDetails, false);
  }

  /// Handles restoration/discarding of previous sheets on back button press
  void _handleBackButton() {
    ActiveSheet previousSheet;

    // Handle different scenarios depending on the current active sheet
    switch (_activeSheet) {
      case ActiveSheet.departureDetails:
      // Check if the last visited sheet was transportDetails
        if (_navigationHistory.isNotEmpty && _navigationHistory.last == ActiveSheet.transportDetails) {
          previousSheet = ActiveSheet.transportDetails;
        } else {
          loadTransportPath(false);
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
        _customInfoWindowController.hideInfoWindow!();
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

  /// Handles sheet transitions
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

  /// Returns title of the current active sheet
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

  /// Renders content of a given sheet
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
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _customInfoWindowController.googleMapController = controller;
              },
              // Creates marker when user presses on screen
              onLongPress: (LatLng position) async {
                await _onLocationSelected(position);
              },
              onCameraMove: (position) {
                _customInfoWindowController.onCameraMove!();
              },
              // Set initial position and zoom of map
              initialCameraPosition:
                  CameraPosition(target: _initialPosition, zoom: 15),
              markers: _markers,
              polylines: _polylines,
              circles: _circles,
            ),
          ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 65,
            width: 150,
            offset: 5,
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

                    // Renders AppBar with title and back button when sheet is fully expanded
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

          // Renders search bar, back button, and map buttons when sheet is unexpanded
          _isSheetFullyExpanded
            ? Container() // Hide search bar when sheet is fully expanded
            : Column(
              children: [
                SizedBox(height: 60),
                Row(
                  children: [
                    // Back button
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
                  // "Show Stops" button
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
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        updateMainPage: null,
      ),
    );
  }
}
