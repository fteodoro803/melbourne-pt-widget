// Patched SearchScreen using SheetNavigator
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
import 'utility/map_utils.dart';
import 'utility/search_utils.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/screen_widgets.dart';
import 'departure_details_sheet.dart';
import 'nearby_stops_sheet.dart';
import 'suggestions_search.dart';
import 'widgets/sheet_navigator.dart'; // <-- import the new SheetNavigator

class SearchScreen extends StatefulWidget {
  final ScreenArguments arguments;
  const SearchScreen({super.key, required this.arguments});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GlobalKey<SheetNavigatorState> _sheetNavigatorKey = GlobalKey<SheetNavigatorState>();
  final GlobalKey<NearbyStopsSheetState> _nearbyStopsSheetKey = GlobalKey<NearbyStopsSheetState>();
  NearbyStopsState? _savedNearbyStopsState;

  final DevTools tools = DevTools();
  final PtvService ptvService = PtvService();
  final GoogleService googleService = GoogleService();
  final TransportPathUtils transportPathUtils = TransportPathUtils();
  final SearchUtils searchUtils = SearchUtils();
  final MapUtils mapUtils = MapUtils();

  late GoogleMapController mapController;
  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController();

  Set<Marker> _markers = {};
  Set<Polyline> _polyLines = {};
  Set<Circle> _circles = {};

  List<LatLng> _geoPath = [];
  List<Departure> _pattern = [];

  Set<Marker> _nearbyStopMarkers = {};
  Set<Marker> _largeRouteMarkers = {};
  Set<Marker> _smallRouteMarkers = {};
  late Marker _stopMarker;
  Marker? _firstMarker;
  Marker? _lastMarker;

  double _currentZoom = 15.0;
  final double _zoomThresholdLarge = 12.8;
  final double _zoomThresholdSmall = 13.4;

  final LatLng _initialPosition = LatLng(-37.813812122509205, 144.96358311072478);

  bool _hasDroppedPin = false;
  bool _showStops = false;
  bool _shouldResetFilters = false;

  String? _tappedStopId;
  Marker? _tappedStopMarker;

  @override
  void initState() {
    super.initState();
    widget.arguments.searchDetails?.distance = 300;
    widget.arguments.searchDetails?.transportType = "all";
    tools.printScreenState("SelectLocation", widget.arguments);
  }

  void _handleBackButton() {
    final nav = _sheetNavigatorKey.currentState;
    if (nav == null) return;

    if (nav.sheetHistory.isNotEmpty) {
      nav.popSheet();
      // Delay to ensure sheet change happens before you check the current one
      Future.delayed(const Duration(milliseconds: 100), () {
        final current = _sheetNavigatorKey.currentState?.currentSheet;
        if (current == 'nearbyStops') {
          setState(() {
            _polyLines.clear();
            resetMarkers();
            showStopMarkers(false);
          });
        }
      });
    } else if (_hasDroppedPin){
      setState(() {
        _hasDroppedPin = false;
        _markers.clear();
        _circles.clear();
        _polyLines.clear();
        _customInfoWindowController.hideInfoWindow!();
      });
    } else {
      // Second back press (no sheet, no map) -> Exit SearchScreen
      Navigator.of(context).pop();
    }
  }

  Widget _buildSheets() {
    return SheetNavigator(
      key: _sheetNavigatorKey,
      initialSheet: 'nearbyStops',
      sheets: {
        'nearbyStops': (ctx, scroll) => NearbyStopsSheet(
          key: _nearbyStopsSheetKey,
          arguments: widget.arguments,
          scrollController: scroll,
          onSearchFiltersChanged: _onSearchFiltersChanged,
          onStopTapped: _onStopTapped,
          initialState: _shouldResetFilters ? null : _savedNearbyStopsState,
          onStateChanged: (state) => _savedNearbyStopsState = state,
          shouldResetFilters: _shouldResetFilters,
        ),
        'stopDetails': (ctx, scroll) => StopDetailsSheet(
          arguments: widget.arguments,
          scrollController: scroll,
          onTransportTapped: _onTransportTapped,
          onDepartureTapped: _onDepartureTapped,
        ),
        'transportDetails': (ctx, scroll) => TransportDetailsSheet(
          arguments: widget.arguments,
          scrollController: scroll,
          onDepartureTapped: _onDepartureTapped,
        ),
        'departureDetails': (ctx, scroll) => DepartureDetailsSheet(
          arguments: widget.arguments,
          scrollController: scroll,
        ),
      },
      onSheetChanged: (sheet) {
        if (sheet == 'nearbyStops') showStopMarkers(true);
      },
    );
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

          _sheetNavigatorKey.currentState?.controller.animateTo(
            0.6,
            duration: const Duration(milliseconds: 300),
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

    GeoPathAndStops geoPathAndStops = await transportPathUtils.addStopsToGeoPath(_geoPath, chosenStopPosition: stopPosition, allStopPositions: isDirectionSpecified ? null : stopPositions);

    newGeoPath = geoPathAndStops.geoPathWithStops;
    chosenStopPositionAlongGeoPath = geoPathAndStops.stopPositionAlongGeoPath!;

    if (!isDirectionSpecified) {
      stopPositions = geoPathAndStops.stopsAlongGeoPath; // stops along route aligned with geoPath
    }

    bool isReverseDirection = isDirectionSpecified ? GeoPathUtils.reverseDirection(newGeoPath, stopPositions) : false;

    PolyLineMarkers polyLineMarkers = await transportPathUtils.setMarkers(
      _markers,
      stopPositions,
      stopPosition: stopPosition,
      stopPositionAlongGeoPath: chosenStopPositionAlongGeoPath,
      isDirectionSpecified,
    );

    _largeRouteMarkers = polyLineMarkers.largeMarkers;
    _smallRouteMarkers = polyLineMarkers.smallMarkers;
    _stopMarker = polyLineMarkers.stopMarker!;
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
      stopPositionAlongGeoPath: chosenStopPositionAlongGeoPath,
      isDirectionSpecified,
      isReverseDirection
    );

    setState(() {
    });
  }

  /// Handles zoom and camera move events
  void _onCameraMove(CameraPosition position) {
    final currentSheet = _sheetNavigatorKey.currentState?.currentSheet;

    if (currentSheet != 'nearbyStops' && _currentZoom != position.zoom) {
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
    _sheetNavigatorKey.currentState?.pushSheet('nearbyStops');

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
    _sheetNavigatorKey.currentState?.pushSheet('stopDetails');
    _customInfoWindowController.hideInfoWindow!();
  }

  /// Handles tap on a direction in StopDetailsSheet
  Future<void> _onTransportTapped(Transport transport) async {
    resetMarkers();
    widget.arguments.transport = transport;

    _sheetNavigatorKey.currentState?.pushSheet('transportDetails');

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

    final currentSheet = _sheetNavigatorKey.currentState?.currentSheet;

    if (currentSheet == 'stopDetails') {
      resetMarkers();
      _pattern = await ptvService.fetchPattern(transport, departure);
      loadTransportPath(true);
    }
    _sheetNavigatorKey.currentState?.pushSheet('departureDetails');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                _customInfoWindowController.googleMapController = controller;
              },
              onLongPress: _onLocationSelected,
              onCameraMove: _onCameraMove,
              initialCameraPosition: CameraPosition(target: _initialPosition, zoom: _currentZoom),
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
          if (_hasDroppedPin) _buildSheets(),
          if (!(_sheetNavigatorKey.currentState?.isExpanded ?? false))
            Column(
              children: [
                SizedBox(height: 60),
                Row(
                  children: [
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
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _showStops = !_showStops);
                    await showStopMarkers(_nearbyStopMarkers.isEmpty);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: !_showStops
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.primaryContainer,
                    minimumSize: Size(40, 40),
                  ),
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_pin),
                        Icon(Icons.tram),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        updateMainPage: null,
      ),
    );
  }
}
