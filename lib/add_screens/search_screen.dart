import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/sheets/route_details_sheet.dart';
import 'package:flutter_project/add_screens/widgets/sheet_navigator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';

import 'package:flutter_project/add_screens/sheets/stop_details_sheet.dart';
import 'package:flutter_project/add_screens/sheets/transport_details_sheet.dart';
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

import 'sheets/departure_details_sheet.dart';
import 'sheets/nearby_stops_sheet.dart';
import 'widgets/suggestions_search.dart';

class SearchScreen extends StatefulWidget {
  final ScreenArguments arguments;
  final bool showRouteDetails;
  final bool showTransportDetails;
  const SearchScreen({super.key, required this.arguments, required this.showRouteDetails, required this.showTransportDetails});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  SearchDetails searchDetails = SearchDetails();

  // DraggableScrollableSheet state management
  final DraggableScrollableController _controller
      = DraggableScrollableController();

  bool _hasDroppedPin = false;
  bool _showStops = false;
  bool _shouldResetFilters = false;

  final GlobalKey<SheetNavigatorState> _sheetNavigatorKey = GlobalKey<SheetNavigatorState>();
  final GlobalKey<NearbyStopsSheetState> _nearbyStopsSheetKey
      = GlobalKey<NearbyStopsSheetState>();
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
  List<Stop> _stopsAlongRoute = [];
  Set<Marker> _nearbyStopMarkers = {};

  late PolyLineMarkers _polyLineMarkers;

  double _currentZoom = 15.0; // Default zoom level

  final LatLng _initialPosition = const LatLng(-37.813812122509205,
      144.96358311072478); //todo: Change based on user's location

  final CustomInfoWindowController _customInfoWindowController
      = CustomInfoWindowController();
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
    searchDetails.distance = 300;
    searchDetails.transportType = "all";
    tools.printScreenState("SelectLocation", widget.arguments);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showRouteDetails) {
        setState(() {
          _hasDroppedPin = true;
        });
        searchDetails.route = widget.arguments.route;
        _sheetNavigatorKey.currentState?.pushSheet('routeDetails');
      } else if (widget.showTransportDetails) {
        searchDetails.transport = widget.arguments.transport;
        setState(() {
          _hasDroppedPin = true;
        });
        _sheetNavigatorKey.currentState?.pushSheet('transportDetails');
      }
    });
  }

  void _handleBackButton() {
    final nav = _sheetNavigatorKey.currentState;
    if (nav == null) return;

    final currentSheet = nav.currentSheet;

    if (currentSheet == 'stopDetails') {
      setState(() {
        _polyLines.clear();
        _stopsAlongRoute.clear();
        _markers = TransportPathUtils.resetMarkers(searchDetails.markerPosition!);
      });
      nav.popSheet();
      return;
    }

    if (currentSheet == 'nearbyStops') {
      setState(() {
        _hasDroppedPin = false;
        _markers.clear();
        _circles.clear();
        _nearbyStopMarkers.clear();
      });
      return;
    }

    if (nav.sheetHistory.isNotEmpty) {
      final prevSheet = nav.sheetHistory.last;
      // If going back to stopDetails from transport or departure, remove direction
      if (prevSheet == 'stopDetails' &&
          (currentSheet == 'transportDetails' || currentSheet == 'departureDetails')) {
        loadTransportPath(false); // reload without direction
      }
      nav.popSheet();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildSheets() {
    return SheetNavigator(
      key: _sheetNavigatorKey,
      initialSheet: widget.showTransportDetails ? 'transportDetails' : widget.showRouteDetails ? 'routeDetails' : 'nearbyStops',
      sheets: {
        'nearbyStops': (ctx, scroll) => NearbyStopsSheet(
          key: _nearbyStopsSheetKey,
          searchDetails: searchDetails,
          scrollController: scroll,
          onSearchFiltersChanged: _onSearchFiltersChanged,
          onStopTapped: _onStopTapped,
          initialState: _shouldResetFilters ? null : _savedNearbyStopsState,
          onStateChanged: (state) => _savedNearbyStopsState = state,
          shouldResetFilters: _shouldResetFilters,
        ),
        'routeDetails': (ctx, scroll) => RouteDetailsSheet(
          searchDetails: searchDetails,
          scrollController: scroll,
          onStopTapped: _onStopTapped,
        ),
        'stopDetails': (ctx, scroll) => StopDetailsSheet(
          searchDetails: searchDetails,
          arguments: widget.arguments,
          scrollController: scroll,
          onTransportTapped: _onTransportTapped,
          onDepartureTapped: _onDepartureTapped,
        ),
        'transportDetails': (ctx, scroll) => TransportDetailsSheet(
          searchDetails: searchDetails,
          arguments: widget.arguments,
          scrollController: scroll,
          onDepartureTapped: _onDepartureTapped,
        ),
        'departureDetails': (ctx, scroll) => DepartureDetailsSheet(
          searchDetails: searchDetails,
          scrollController: scroll,
        ),
      },
      onSheetChanged: (sheet) {
        if (sheet == 'nearbyStops') showStopMarkers(true);
      },
    );
  }

  NearbyStopsState? _getNearbyStopsState() {
    if (_nearbyStopsSheetKey.currentState != null) {
      return _nearbyStopsSheetKey.currentState!.getCurrentState();
    }
    return null;
  }

  /// Shows nearby stops on map when button is toggled by user
  Future<void> showStopMarkers(bool refresh) async {
    if (_showStops) {
      _tappedStopId = null;

      if (refresh) {
        _nearbyStopMarkers = await mapUtils.generateNearbyStopMarkers(
          stops: searchDetails.stops!,
          getIcon: (stop) => transportPathUtils.getResizedImage(
              "assets/icons/PTV ${stop.routeType!.name} Logo.png", 20, 20),
          onTapStop: handleStopTapOnMap,
        );
      }

      setState(() {
        _markers = TransportPathUtils.resetMarkers(
            searchDetails.markerPosition!);
        _markers = {..._markers, ..._nearbyStopMarkers};
        _circles.clear();
        _circles.add(
          Circle(
            circleId: CircleId("circle"),
            center: searchDetails.markerPosition!,
            fillColor: Colors.blue.withOpacity(0.2),
            strokeWidth: 0,
            radius: searchDetails.distance!.toDouble(),
          ),
        );
      });
    } else {
      setState(() {
        _customInfoWindowController.hideInfoWindow!();
        _circles.clear();
        _markers = TransportPathUtils.resetMarkers(
            searchDetails.markerPosition!);
      });
    }
  }

  void handleStopTapOnMap(Stop stop) async {
    final largeIcon = await transportPathUtils.getResizedImage(
        "assets/icons/PTV ${stop.routeType?.name} Logo Outlined.png", 35, 35);

    setState(() {
      for (var s in searchDetails.stops!) {
        s.isExpanded = false;
      }
      stop.isExpanded = true;

      if (_tappedStopId != null) {
        _markers.removeWhere((m) => m.markerId == MarkerId(_tappedStopId!));
        _markers.add(_tappedStopMarker!);
      }

      _tappedStopMarker = _markers.firstWhere(
              (m) => m.markerId == MarkerId(stop.id.toString()));
      _markers.removeWhere((m) => m.markerId == MarkerId(stop.name));

      _tappedStopId = stop.id.toString();
      _markers.add(Marker(
        markerId: MarkerId(_tappedStopId!),
        position: LatLng(stop.latitude!, stop.longitude!),
        icon: largeIcon,
        consumeTapEvents: true,
      ));

      _customInfoWindowController.addInfoWindow!(
        StopInfoWindow(stop: stop),
        LatLng(stop.latitude!, stop.longitude!),
      );

      int stopIndex = searchDetails.stops!.indexOf(stop);

      _sheetNavigatorKey.currentState?.animateSheetTo(0.6);

      Future.delayed(Duration(milliseconds: 100), () {
        _nearbyStopsSheetKey.currentState?.scrollToStopItem(stopIndex);
      });
    });
  }

  /// Loads route geo path and stops on map
  Future<void> loadTransportPath(bool isDirectionSpecified) async {
    LatLng stopPosition;
    List<Stop> stops = [];
    stopPosition = LatLng(
        searchDetails.stop!.latitude!, searchDetails.stop!.longitude!);

    // Early exit if GeoPath is empty // todo: also check if null!!!
    if (_geoPath.isEmpty || _stopsAlongRoute.isEmpty) {
      return;
    }

    stops = _stopsAlongRoute.where((s) => s.stopSequence != 0).toList();

    List<LatLng> stopPositions = [];
    LatLng chosenStopPositionAlongGeoPath = stopPosition;
    List<LatLng> newGeoPath = [];

    for (var stop in stops) {
      var pos = LatLng(stop.latitude!, stop.longitude!);
      stopPositions.add(pos);
    }

    GeoPathAndStops geoPathAndStop
      = await transportPathUtils.addStopToGeoPath(_geoPath, stopPosition);

    newGeoPath = geoPathAndStop.geoPathWithStop;
    chosenStopPositionAlongGeoPath = geoPathAndStop.stopPositionAlongGeoPath!;

    bool isReverseDirection = isDirectionSpecified
      ? GeoPathUtils.reverseDirection(newGeoPath, stopPositions)
      : false;

    _polyLineMarkers = await transportPathUtils.setMarkers(
      _markers,
      stopPositions,
      stopPosition: stopPosition,
      isDirectionSpecified,
    );

    _markers = {
      ..._markers,
      ..._polyLineMarkers.largeMarkers,
      ..._polyLineMarkers.smallMarkers
    };
    _markers.add(_polyLineMarkers.stopMarker!);
    _markers.add(_polyLineMarkers.firstMarker);
    _markers.add(_polyLineMarkers.lastMarker);

    _polyLines = await transportPathUtils.loadRoutePolyline(
      searchDetails.route!.colour!,
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

    if (currentSheet != 'nearbyStops'
        && currentSheet != null
        && _currentZoom != position.zoom) {
      if (mapUtils.didZoomChange(_currentZoom, position.zoom)) {
        setState(() {
          _markers = mapUtils.onZoomChange(
              _markers, position.zoom,
              _polyLineMarkers,
              searchDetails.markerPosition!
          );
          _currentZoom = position.zoom;
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
    String address = await mapUtils.getAddressFromCoordinates(
        selectedLocation.latitude, selectedLocation.longitude);
    List<Stop> uniqueStops = await searchUtils.getStops(
        selectedLocation, "all", 300);

    // Update the state with the new address
    searchDetails.stops = uniqueStops;
    searchDetails.markerPosition = selectedLocation;
    searchDetails.address = address;
    searchDetails.distance = 300;
    searchDetails.transportType = "all";
    _hasDroppedPin = true;

    _customInfoWindowController.hideInfoWindow!();

    final zoom = await mapController.getZoomLevel();

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: await mapUtils.calculateOffsetPosition(
              selectedLocation, 0.35, mapController),
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
    String transportType = newTransportType ?? searchDetails.transportType!;
    int oldDistance = searchDetails.distance!;
    int distance = newDistance ?? oldDistance;

    List<Stop> uniqueStops = await searchUtils.getStops(
        searchDetails.markerPosition!, transportType, distance);

    if (oldDistance != newDistance && newDistance != null) {
      LatLngBounds bounds = await mapUtils.calculateBoundsForMarkers(
          distance.toDouble(), searchDetails.markerPosition!);

      // First animate to the bounds to ensure all points are visible
      mapController.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );

      // Then adjust the position so the marker is at 70% of height
      await Future.delayed(Duration(milliseconds: 300)); // Wait for first animation to complete

      final LatLng markerPosition = searchDetails.markerPosition!;
      final zoom = await mapController.getZoomLevel();

      // Calculate a point that will position our marker at 70% of the map height
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: await mapUtils.calculateOffsetPosition(
                markerPosition, 0.3, mapController),
            zoom: zoom,
          ),
        ),
      );
    }

    setState(() {
      searchDetails.stops = uniqueStops;
      searchDetails.distance = distance;
      searchDetails.transportType = transportType;
      showStopMarkers(true);
    });


  }

  /// Handles tap on a route in NearbyStopsSheet
  Future<void> _onStopTapped(Stop stop, pt_route.Route route) async {
    _circles.clear();
    _markers = TransportPathUtils.resetMarkers(searchDetails.markerPosition!); // todo: add geopath to routedetails
    List<Transport> listTransport =
      await searchUtils.splitDirection(stop, route);

    searchDetails.stop = stop;
    searchDetails.route = route;

    searchDetails.directions = [];
    for (var transport in listTransport) {
      searchDetails.directions!.add(transport);
    }

    _geoPath = await ptvService.fetchGeoPath(route); // get geoPath of route
    if (listTransport.isNotEmpty) {
      _stopsAlongRoute = await ptvService.fetchStopsRoute(
          listTransport[0].route!, direction: listTransport[0].direction);
    }
    else {
      _stopsAlongRoute = [];
    }

    loadTransportPath(false);
    _sheetNavigatorKey.currentState?.pushSheet('stopDetails');
    _customInfoWindowController.hideInfoWindow!();
  }

  /// Handles tap on a direction in StopDetailsSheet
  Future<void> _onTransportTapped(Transport transport) async {
    _markers = TransportPathUtils.resetMarkers(searchDetails.markerPosition!);
    searchDetails.transport = transport;

    _sheetNavigatorKey.currentState?.pushSheet('transportDetails');
    _stopsAlongRoute = await ptvService.fetchStopsRoute(
        transport.route!, direction: transport.direction);

    loadTransportPath(true);

  }

  /// Handles tap on a departure in StopDetailsSheet and TransportDetailsSheet
  Future<void> _onDepartureTapped(Departure departure, Transport transport) async {
    searchDetails.transport = transport;
    searchDetails.departure = departure;

    if (_sheetNavigatorKey.currentState?.currentSheet == 'stopDetails') {
      _markers = TransportPathUtils.resetMarkers(
          searchDetails.markerPosition!);
      _stopsAlongRoute = await ptvService.fetchStopsRoute(
          transport.route!, direction: transport.direction);
      loadTransportPath(true);
    }
    _sheetNavigatorKey.currentState?.pushSheet('departureDetails');
  }

  // Rendering
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
                  if (!widget.showTransportDetails && !widget.showRouteDetails)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: SuggestionsSearch(onLocationSelected: _onLocationSelected),
                    ),
                ],
              ),
              if (_hasDroppedPin && !widget.showTransportDetails && !widget.showRouteDetails)
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
          if (_hasDroppedPin) _buildSheets(),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        updateMainPage: null,
      ),
    );
  }
}
