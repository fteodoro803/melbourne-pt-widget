import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';

import 'package:flutter_project/add_screens/stop_details_sheet.dart';
import 'package:flutter_project/add_screens/transport_details_sheet.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/services/google_service.dart';

import '../ptv_info_classes/departure_info.dart';
import '../ptv_info_classes/stop_info.dart';
import '../ptv_info_classes/route_info.dart' as pt_route;

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
  bool _shouldResetFilters = false;
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
  Set<Polyline> _polyLines = {};
  Set<Circle> _circles = {};
  List<LatLng> _geoPath = [];
  List<Departure> _pattern = [];

  Set<Marker> _nearbyStopMarkers = {};
  Set<Marker> _largeRouteMarkers = {};
  Set<Marker> _smallRouteMarkers = {};
  late Marker _stopMarker;
  late Marker? _firstMarker;
  late Marker? _lastMarker;

  double _currentZoom = 15.0; // Default zoom level
  final double _zoomThresholdLarge = 12.8; // Zoom level threshold to hide the marker
  final double _zoomThresholdSmall = 13.4;

  final LatLng _initialPosition = const LatLng(-37.813812122509205,
      144.96358311072478); //todo: Change based on user's location

  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController();
  String? _tappedStopId;
  Marker? _tappedStopMarker;


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
  void resetMarkers() {
    _markers.clear();

    LatLng position = widget.arguments.searchDetails!.markerPosition!;
    MarkerId id = MarkerId(position.toString()); // Unique ID based on position

    _markers.add(Marker(
      markerId: id,
      position: position,
      consumeTapEvents: true,
      infoWindow: InfoWindow(
        snippet: "Marker",
        title: "Marker"
      ),
    ));
  }

  /// Shows nearby stops on map when button is toggled by user
  Future<void> showStopMarkers(bool refresh) async {
    if (_showStops) {

      _tappedStopId = null;

      if (refresh) {
        _nearbyStopMarkers = {};
        for (var stop in widget.arguments.searchDetails!.stops) {

          Marker newMarker = await createNearbyStopMarker(stop);

          _nearbyStopMarkers.add(newMarker);
        }
      }

      setState(() {
        resetMarkers();
        _markers = {..._markers, ..._nearbyStopMarkers};

        _circles.clear();
        _circles.add(
          Circle(
            circleId: CircleId("circle"),
            center: widget.arguments.searchDetails!.markerPosition!,
            fillColor: Colors.blue.withValues(alpha: 0.2),
            strokeWidth: 0,
            radius: widget.arguments.searchDetails!.distance.toDouble(),
            )
        );
      });
    }
    else {
      _circles.clear();
      resetMarkers();
    }
  }

  /// Generates marker for a nearby stop
  Future<Marker> createNearbyStopMarker(Stop stop) async {
    BitmapDescriptor? customMarkerIcon = await transportPathUtils.getResizedImage("assets/icons/PTV ${stop.routeType?.name} Logo.png", 20, 20);
    BitmapDescriptor? largeCustomMarkerIcon = await transportPathUtils.getResizedImage("assets/icons/PTV ${stop.routeType?.name} Logo Outlined.png", 35, 35);

    LatLng stopPosition = LatLng(stop.latitude!, stop.longitude!);

    Marker newMarker = Marker(
      markerId: MarkerId(stop.id.toString()),
      position: stopPosition,
      icon: customMarkerIcon,
      consumeTapEvents: true,
      // anchor: const Offset(0.5, 0.5),
      onTap: () {
        setState(() {

          // Set isExpanded to false for every other nearby stop
          for (var s in widget.arguments.searchDetails!.stops) {
            s.isExpanded = false;
          }
          stop.isExpanded = true;

          // If a previous stop was tapped, remove the large marker from _nearbyStopMarkers and add the small marker back
          if (_tappedStopId != null) {
            _markers.removeWhere((marker) => marker.markerId == MarkerId(_tappedStopId!));
            _markers.add(_tappedStopMarker!);
          }

          // Remove the small marker of the newly tapped stop from _nearbyStopMarkers and store small marker
          _tappedStopMarker = _markers.firstWhere(
                (marker) => marker.markerId == MarkerId(stop.id.toString()),
          );
          _markers.removeWhere((marker) => marker.markerId == MarkerId(stop.name));

          // Add the large marker of the newly tapped stop to _nearbyStopMarkers
          _tappedStopId = stop.id.toString();
          _markers.add(Marker(
            markerId: MarkerId(_tappedStopId!),
            position: stopPosition,
            icon: largeCustomMarkerIcon,
            consumeTapEvents: true,
            // anchor: const Offset(0.5, 0.5),
          ),
          );

          // Render the info window of the tapped stop
          _customInfoWindowController.addInfoWindow!(
            StopInfoWindow(stop: stop),
            stopPosition, // Position of the info window
          );

          // Find the index of the tapped stop
          int stopIndex = widget.arguments.searchDetails!.stops.indexOf(stop);

          // First ensure the sheet is expanded enough to see the content
          _controller.animateTo(
            0.6, // Adjust as needed
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
    );
    return newMarker;
  }

  /// Loads route geo path and stops on map
  Future<void> loadTransportPath(bool isDirectionSpecified) async {
    LatLng stopPosition;
    List<Stop> stops = [];
    stopPosition = LatLng(widget.arguments.searchDetails!.stop!.latitude!, widget.arguments.searchDetails!.stop!.longitude!);
    List<Stop> allStopsAlongRoute = await ptvService.fetchStopsRoute(widget.arguments.searchDetails!.route!); // all stops along a given route

    // Early exit if GeoPath is empty // todo: also check if null!!!
    if (_geoPath.isEmpty || _pattern.isEmpty || allStopsAlongRoute.isEmpty) {
      return;
    }

    // Only add stops that are in the pattern, in order provided
    for (var d in _pattern) {
      stops.add(allStopsAlongRoute[allStopsAlongRoute.indexWhere((stop) => stop.id == d.stopId)]);
    }

    List<LatLng> stopPositions = [];
    LatLng chosenStopPositionAlongGeoPath = stopPosition;
    List<LatLng> newGeoPath = [];

    for (var stop in stops) {
      var pos = LatLng(stop.latitude!, stop.longitude!);
      stopPositions.add(pos);
    }

    GeoPathAndStops geoPathAndStops = await transportPathUtils.addStopsToGeoPath(_geoPath, stopPosition, allStopPositions: isDirectionSpecified ? null : stopPositions);

    newGeoPath = geoPathAndStops.geoPathWithStops;
    chosenStopPositionAlongGeoPath = geoPathAndStops.stopPositionAlongGeoPath;

    if (!isDirectionSpecified) {
      stopPositions = geoPathAndStops.stopsAlongGeoPath; // stops along route aligned with geoPath
    }

    bool isReverseDirection = isDirectionSpecified ? GeoPathUtils.reverseDirection(newGeoPath, stopPositions) : false;

    PolyLineMarkers polyLineMarkers = await transportPathUtils.setMarkers(
      _markers,
      stopPositions,
      stopPosition,
      chosenStopPositionAlongGeoPath,
      isDirectionSpecified,
    );

    _largeRouteMarkers = polyLineMarkers.largeMarkers;
    _smallRouteMarkers = polyLineMarkers.smallMarkers;
    _stopMarker = polyLineMarkers.stopMarker;
    _firstMarker = polyLineMarkers.firstMarker;
    _lastMarker = polyLineMarkers.lastMarker;

    _markers = {..._markers, ..._largeRouteMarkers, ..._smallRouteMarkers};
    _markers.add(_stopMarker);
    if (_firstMarker != null) {
      _markers.add(_firstMarker!);
    }
    if (_lastMarker != null) {
      _markers.add(_lastMarker!);
    }

    _polyLines = await transportPathUtils.loadRoutePolyline(
      widget.arguments.searchDetails!.route!.colour!,
      newGeoPath,
      chosenStopPositionAlongGeoPath,
      isDirectionSpecified,
      isReverseDirection
    );

    setState(() {
    });
  }

  /// Handles zoom and camera move events
  void _onCameraMove(CameraPosition position) {
    if (_activeSheet != ActiveSheet.nearbyStops && _activeSheet != ActiveSheet.none && _currentZoom != position.zoom) {
      _currentZoom = position.zoom;
      if (_currentZoom < _zoomThresholdLarge) {
        setState(() {
          resetMarkers();
          _markers.add(_stopMarker);
          if (_firstMarker != null) {
            _markers.add(_firstMarker!);
          }
          if (_lastMarker != null) {
            _markers.add(_lastMarker!);
          }
        });
      } else if (_currentZoom < _zoomThresholdSmall && _currentZoom >= _zoomThresholdLarge) {
        setState(() {
          resetMarkers();
          _markers.add(_stopMarker);
          if (_firstMarker != null) {
            _markers.add(_firstMarker!);
          }
          if (_lastMarker != null) {
            _markers.add(_lastMarker!);
          }
          _markers = {..._markers, ..._largeRouteMarkers};
        });
      }
      else {
        // Re-add the marker when zoom is above the threshold
        setState(() {
          _markers = {..._markers, ..._smallRouteMarkers, ..._largeRouteMarkers};
        });
      }
    }
    else {
      _customInfoWindowController.onCameraMove!();
    }
  }

  /// Set the map's Marker and Camera to a new marker location
  Future<void> _onLocationSelected(LatLng selectedLocation) async {
    _circles.clear();
    _polyLines.clear();
    _nearbyStopMarkers.clear();

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

    setState(() {
      _shouldResetFilters = true;
    });

    // Bring the user to the NearbyStopsSheet with the updated data
    _changeSheet(ActiveSheet.nearbyStops, true);

    showStopMarkers(true);
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

    setState(() {
      widget.arguments.searchDetails!.stops = uniqueStops;
      widget.arguments.searchDetails!.distance = distance;
      widget.arguments.searchDetails!.transportType = transportType;
      showStopMarkers(true);
    });


  }

  /// Handles tap on a route in NearbyStopsSheet
  Future<void> _onStopTapped(Stop stop, pt_route.Route route) async {
    _circles.clear();
    resetMarkers();
    List<Transport> listTransport = await searchUtils.splitDirection(stop, route);

    widget.arguments.searchDetails!.stop = stop;
    widget.arguments.searchDetails!.route = route;

    widget.arguments.searchDetails!.directions.clear();
    for (var transport in listTransport) {
      widget.arguments.searchDetails!.directions.add(transport);
    }

    _geoPath = await ptvService.fetchGeoPath(route); // get geoPath of route
    if (listTransport.first.departures != null && listTransport.first.departures!.isNotEmpty) {
      _pattern = await ptvService.fetchPattern(listTransport[0], listTransport[0].departures![0]);
    }
    else {
      _pattern = [];
    }

    loadTransportPath(false);
    _changeSheet(ActiveSheet.stopDetails, false);
    _customInfoWindowController.hideInfoWindow!();
  }

  /// Handles tap on a direction in StopDetailsSheet
  Future<void> _onTransportTapped(Transport transport) async {
    resetMarkers();
    widget.arguments.transport = transport;

    _changeSheet(ActiveSheet.transportDetails, false);

    if (transport.departures != null && transport.departures!.isNotEmpty) {
      _pattern = await ptvService.fetchPattern(transport, transport.departures![0]);
    }
    else {
      _pattern = [];
    }

    loadTransportPath(true);

  }

  /// Handles tap on a departure in StopDetailsSheet and TransportDetailsSheet
  Future<void> _onDepartureTapped(Departure departure, Transport transport) async {
    widget.arguments.transport = transport;
    widget.arguments.searchDetails!.departure = departure;

    if (_activeSheet == ActiveSheet.stopDetails) {
      resetMarkers();
      _pattern = await ptvService.fetchPattern(transport, departure);
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
          resetMarkers();
          _polyLines.clear();
          loadTransportPath(false);
          previousSheet = ActiveSheet.stopDetails;
        }
        break;

      case ActiveSheet.transportDetails:
        previousSheet = ActiveSheet.stopDetails;
        resetMarkers();
        _polyLines.clear();
        // Restore transport path display
        loadTransportPath(false);
        break;

      case ActiveSheet.stopDetails:
        previousSheet = ActiveSheet.nearbyStops;
        // Clear polylines and restore marker
        _polyLines.clear();
        resetMarkers();
        showStopMarkers(false);
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
        final sheet = NearbyStopsSheet(
          key: _nearbyStopsSheetKey,
          arguments: widget.arguments,
          scrollController: scrollController,
          onSearchFiltersChanged: _onSearchFiltersChanged,
          onStopTapped: _onStopTapped,
          initialState: _shouldResetFilters ? null : _savedNearbyStopsState,
          onStateChanged: (state) {
            _savedNearbyStopsState = state;
          },
          shouldResetFilters: _shouldResetFilters,
        );

        // Reset the flag after rendering
        if (_shouldResetFilters) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _shouldResetFilters = false;
            });
          });
        }

        return sheet;
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
              onCameraMove: _onCameraMove,
              // Set initial position and zoom of map
              initialCameraPosition:
                  CameraPosition(target: _initialPosition, zoom: _currentZoom),
              markers: _markers,
              polylines: _polyLines,
              circles: _circles,
            ),
          ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 36,
            width: 360,
            offset: 0,
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

                    // DraggableScrollableSheet shadow
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
                                onPressed: () {
                                  scrollController.jumpTo(0);
                                  _handleBackButton();
                                }
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
                                onPressed: () {
                                  _controller.jumpTo(0.6);
                                  scrollController.jumpTo(0);
                                } ,
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

                // "Show Stops" button
                if (_activeSheet == ActiveSheet.nearbyStops)
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _showStops = !_showStops;
                      });
                      await showStopMarkers(_nearbyStopMarkers.isEmpty ? true : false);
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
