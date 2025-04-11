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
  final SearchDetails searchDetails;

  const SearchScreen({
    super.key,
    required this.arguments,
    required this.searchDetails
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  late SearchDetails _searchDetails;

  bool _showSheet = false;
  bool _showStops = false;
  bool _shouldResetFilters = false;
  bool? _enableSearch;

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
    _searchDetails = widget.searchDetails;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_searchDetails.route != null
          && (_enableSearch == false || _enableSearch == null)) {
        _enableSearch = false;

        await _initialiseGeoPathForRoute(true);
        await _loadTransportPath(false);

        setState(() {
          _showSheet = true;
        });

        _sheetNavigatorKey.currentState?.pushSheet('Route Details');

      } else if (_searchDetails.transport != null
          && (_enableSearch == false || _enableSearch == null)) {
        _enableSearch = false;
        _searchDetails.stop = _searchDetails.transport!.stop;
        _searchDetails.route = _searchDetails.transport!.route;

        await _initialiseGeoPathForRoute(true);
        await _loadTransportPath(true);

        setState(() {
          _showSheet = true;
        });

        _sheetNavigatorKey.currentState?.pushSheet('Transport Details');
      }
      else {
        setState(() {
          _enableSearch = true;
          _searchDetails.distance = 300;
          _searchDetails.transportType = "all";
        });
      }
    });
  }

  Future<void> _initialiseGeoPathForRoute(bool newRoute) async {
    if (_searchDetails.route!.directions == null || _searchDetails.route!.directions!.isEmpty) {
      _searchDetails.route!.directions = await ptvService.fetchDirections(_searchDetails.route!.id);
    }
    if (_searchDetails.route!.stopsAlongRoute == null || _searchDetails.route!.stopsAlongRoute!.isEmpty) {
      _searchDetails.route!.stopsAlongRoute =
        await searchUtils.getStopsAlongRoute(
          _searchDetails.route!.directions!, _searchDetails.route!);
    }
    if (newRoute) {
      _geoPath = await ptvService.fetchGeoPath(_searchDetails.route!);
    }
  }

  void _handleSheetExpansion(bool isExpanded) {
    setState(() {
      widget.searchDetails.isSheetExpanded = isExpanded;
    });
  }

  /// Loads route geo path and stops on map
  Future<void> _loadTransportPath(bool isDirectionSpecified) async {

    // Early exit if GeoPath is empty
    if (_geoPath.isEmpty || _searchDetails.route!.stopsAlongRoute == null
        || _searchDetails.route!.stopsAlongRoute!.isEmpty) {
      return;
    }

    LatLng? stopPosition;

    if (_searchDetails.stop != null) {
      stopPosition = LatLng(
          _searchDetails.stop!.latitude!, _searchDetails.stop!.longitude!);
    }

    List<LatLng> stopPositions = [];
    LatLng? chosenStopPositionAlongGeoPath = stopPosition;
    List<LatLng> newGeoPath = [..._geoPath];

    for (var stop in _searchDetails.route!.stopsAlongRoute!) {
      var pos = LatLng(stop.latitude!, stop.longitude!);
      stopPositions.add(pos);
    }

    if (stopPosition != null) {
      GeoPathAndStops geoPathAndStop
      = await transportPathUtils.addStopToGeoPath(_geoPath, stopPosition);

      newGeoPath = geoPathAndStop.geoPathWithStop;
      chosenStopPositionAlongGeoPath = geoPathAndStop.stopPositionAlongGeoPath!;
    }

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
    if (_polyLineMarkers.stopMarker != null) {
      _markers.add(_polyLineMarkers.stopMarker!);

    }
    _markers.add(_polyLineMarkers.firstMarker);
    _markers.add(_polyLineMarkers.lastMarker);

    _polyLines = await transportPathUtils.loadRoutePolyline(
        _searchDetails.route!.colour!,
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

    if (currentSheet != 'Nearby Stops'
        && currentSheet != null
        && _currentZoom != position.zoom) {
      if (mapUtils.didZoomChange(_currentZoom, position.zoom)) {
        setState(() {
          _markers = mapUtils.onZoomChange(
              _markers, position.zoom,
              _polyLineMarkers,
              _searchDetails.markerPosition
          );
          _currentZoom = position.zoom;
        });
      }
    }
    else {
      _customInfoWindowController.onCameraMove!();
    }
  }

  /// Shows nearby stops on map when button is toggled by user
  Future<void> _showStopMarkers(bool refresh) async {
    if (_showStops) {
      _tappedStopId = null;

      if (refresh) {
        _nearbyStopMarkers = await mapUtils.generateNearbyStopMarkers(
          stops: _searchDetails.stops!,
          getIcon: (stop) => transportPathUtils.getResizedImage(
              "assets/icons/PTV ${stop.routeType!.name} Logo.png", 20, 20),
          onTapStop: _handleStopTapOnMap,
        );
      }

      setState(() {
        _markers = TransportPathUtils.resetMarkers(
            _searchDetails.markerPosition!);
        _markers = {..._markers, ..._nearbyStopMarkers};
        _circles.clear();
        _circles.add(
          Circle(
            circleId: CircleId("circle"),
            center: _searchDetails.markerPosition!,
            fillColor: Colors.blue.withValues(alpha: 0.2),
            strokeWidth: 0,
            radius: _searchDetails.distance!.toDouble(),
          ),
        );
      });
    } else {
      setState(() {
        _customInfoWindowController.hideInfoWindow!();
        _circles.clear();
        _markers = TransportPathUtils.resetMarkers(
            _searchDetails.markerPosition!);
      });
    }
  }

  void _handleStopTapOnMap(Stop stop) async {
    final largeIcon = await transportPathUtils.getResizedImage(
        "assets/icons/PTV ${stop.routeType?.name} Logo Outlined.png", 35, 35);

    setState(() {
      for (var s in _searchDetails.stops!) {
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

      int stopIndex = _searchDetails.stops!.indexOf(stop);

      _sheetNavigatorKey.currentState?.animateSheetTo(0.6);

      Future.delayed(Duration(milliseconds: 100), () {
        _nearbyStopsSheetKey.currentState?.scrollToStopItem(stopIndex);
      });
    });
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
    _searchDetails.stops = uniqueStops;
    _searchDetails.markerPosition = selectedLocation;
    _searchDetails.address = address;
    _searchDetails.distance = 300;
    _searchDetails.transportType = "all";
    _showSheet = true;

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
    _sheetNavigatorKey.currentState?.pushSheet('Nearby Stops');

    _showStopMarkers(true);
  }

  /// Handles changes in transport type and distance filters on NearbyStopsSheet
  Future<void> _onSearchFiltersChanged({String? newTransportType, int? newDistance}) async {
    String transportType = newTransportType ?? _searchDetails.transportType!;
    int oldDistance = _searchDetails.distance!;
    int distance = newDistance ?? oldDistance;

    List<Stop> uniqueStops = await searchUtils.getStops(
        _searchDetails.markerPosition!, transportType, distance);

    if (oldDistance != newDistance && newDistance != null) {
      LatLngBounds bounds = await mapUtils.calculateBoundsForMarkers(
          distance.toDouble(), _searchDetails.markerPosition!);

      // First animate to the bounds to ensure all points are visible
      mapController.moveCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );

      // Then adjust the position so the marker is at 70% of height
      await Future.delayed(Duration(milliseconds: 300)); // Wait for first animation to complete

      final LatLng markerPosition = _searchDetails.markerPosition!;
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
      _searchDetails.stops = uniqueStops;
      _searchDetails.distance = distance;
      _searchDetails.transportType = transportType;
      _showStopMarkers(true);
    });


  }

  /// Handles tap on a route in NearbyStopsSheet
  Future<void> _onStopSelected(Stop stop, pt_route.Route route, bool newRoute) async {
    _circles.clear();
    _markers = TransportPathUtils.resetMarkers(_searchDetails.markerPosition);
    List<Transport> listTransport =
      await searchUtils.splitDirection(stop, route);

    _searchDetails.stop = stop;
    _searchDetails.route = route;

    _searchDetails.transportList = [];
    for (var transport in listTransport) {
      _searchDetails.transportList!.add(transport);
    }

    await _initialiseGeoPathForRoute(newRoute);

    _loadTransportPath(false);
    _sheetNavigatorKey.currentState?.pushSheet('Stop Details');
    _customInfoWindowController.hideInfoWindow!();
  }

  /// Handles tap on a direction in StopDetailsSheet
  Future<void> _onTransportSelected(Transport transport) async {
    _markers = TransportPathUtils.resetMarkers(_searchDetails.markerPosition!);
    _searchDetails.transport = transport;

    _sheetNavigatorKey.currentState?.pushSheet('Transport Details');

    _loadTransportPath(true);

  }

  /// Handles tap on a departure in StopDetailsSheet and TransportDetailsSheet
  Future<void> _onDepartureSelected(Departure departure, Transport transport) async {
    _searchDetails.transport = transport;
    _searchDetails.departure = departure;

    if (_sheetNavigatorKey.currentState?.currentSheet == 'Stop Details') {

      _markers = TransportPathUtils.resetMarkers(_searchDetails.markerPosition);
      _loadTransportPath(true);
    }
    _sheetNavigatorKey.currentState?.pushSheet('Departure Details');
  }

  Widget _buildSheets() {
    return SheetNavigator(
      key: _sheetNavigatorKey,
      initialSheet: _searchDetails.transport != null
          ? 'Transport Details'
          : _searchDetails.route != null
            ? 'Route Details'
            : 'Nearby Stops',
      sheets: {
        'Nearby Stops': (ctx, scroll) => NearbyStopsSheet(
          key: _nearbyStopsSheetKey,
          searchDetails: _searchDetails,
          scrollController: scroll,
          onSearchFiltersChanged: _onSearchFiltersChanged,
          onStopTapped: _onStopSelected,
          initialState: _shouldResetFilters ? null : _savedNearbyStopsState,
          onStateChanged: (state) => _savedNearbyStopsState = state,
          shouldResetFilters: _shouldResetFilters,
        ),
        'Route Details': (ctx, scroll) => RouteDetailsSheet(
          searchDetails: _searchDetails,
          scrollController: scroll,
          onStopTapped: _onStopSelected,
        ),
        'Stop Details': (ctx, scroll) => StopDetailsSheet(
          searchDetails: _searchDetails,
          arguments: widget.arguments,
          scrollController: scroll,
          onTransportTapped: _onTransportSelected,
          onDepartureTapped: _onDepartureSelected,
        ),
        'Transport Details': (ctx, scroll) => TransportDetailsSheet(
          searchDetails: _searchDetails,
          arguments: widget.arguments,
          scrollController: scroll,
          onDepartureTapped: _onDepartureSelected,
        ),
        'Departure Details': (ctx, scroll) => DepartureDetailsSheet(
          searchDetails: _searchDetails,
          scrollController: scroll,
        ),
      },
      onSheetChanged: (sheet) {
        if (sheet == 'Nearby Stops') _showStopMarkers(true);
      },
      handleSheetExpansion: _handleSheetExpansion,
    );
  }

  void _handleBackButton() {
    final nav = _sheetNavigatorKey.currentState;

    // If we're viewing a sheet
    if (nav != null) {
      final currentSheet = nav.currentSheet;

      if (currentSheet == 'Nearby Stops') {
        // If we're at the root level sheet (Nearby Stops)
        setState(() {
          _showSheet = false;
          _markers.clear();
          _circles.clear();
          _nearbyStopMarkers.clear();
        });

        return;
      }

      // If we're in a nested sheet
      if (nav.sheetHistory.isNotEmpty) {
        final prevSheet = nav.sheetHistory.last;
        // Handle sheet-specific logic
        if (prevSheet == 'Stop Details' &&
            (currentSheet == 'Transport Details' || currentSheet == 'Departure Details')) {
          _loadTransportPath(false); // reload without direction
        }
        if (prevSheet == 'Nearby Stops' && currentSheet == 'Stop Details') {
          setState(() {
            _polyLines.clear();
            _markers = TransportPathUtils.resetMarkers(_searchDetails.markerPosition);
          });
        }
        nav.popSheet();
        return;
      }
    }

    // If no sheets are active or we can't handle it with the sheet navigator
    // Force navigation to home
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
                  if (_enableSearch != null && _enableSearch == true)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: SuggestionsSearch(onLocationSelected: _onLocationSelected),
                    ),
                ],
              ),
              if (_showSheet && _enableSearch != null && _enableSearch == true)
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _showStops = !_showStops);
                    await _showStopMarkers(_nearbyStopMarkers.isEmpty);
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
          if (_showSheet) _buildSheets(),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        updateMainPage: null,
      ),
    );
  }
}
