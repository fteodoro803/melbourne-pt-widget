import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/departure_details_sheet.dart';
import 'package:flutter_project/add_screens/transport_details_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utility/map_utils.dart';
import '../ptv_info_classes/departure_info.dart';
import '../ptv_info_classes/stop_info.dart';
import '../screen_arguments.dart';
import '../ptv_service.dart';
import '../transport.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/screen_widgets.dart';

class TransportMap extends StatefulWidget {
  final ScreenArguments arguments;

  TransportMap({
    super.key,
    required this.arguments,
  });

  @override
  _TransportMapState createState() => _TransportMapState();
}

class _TransportMapState extends State<TransportMap> {
  late Transport _transport;
  bool _isDepartureSelected = false;

  // Google Maps controller and center position
  late GoogleMapController mapController;
  late LatLng _center = const LatLng(-37.813812122509205, 144.96358311072478);
  late double _zoom = 13;

  late LatLng _stopPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polyLines = {};
  late List<LatLng> _geoPath = [];
  late List<Departure> _pattern = [];

  PtvService ptvService = PtvService();
  TransportPathUtils transportPathUtils = TransportPathUtils();

  @override
  void initState() {
    super.initState();
    _transport = widget.arguments.transport;
    _stopPosition = LatLng(_transport.stop!.latitude!, _transport.stop!.longitude!);
    _center = _stopPosition;

    fetchGeoPath();
  }

  Future<void> fetchGeoPath() async {
    _geoPath = await ptvService.fetchGeoPath(_transport.route!);
    if (_transport.departures != null && _transport.departures!.isNotEmpty) {
      _pattern = await ptvService.fetchPattern(_transport, _transport.departures![0]);
    }
    else {
      _pattern = [];
    }

    loadTransportPath();
  }

  /// Loads route geo path and stops on map
  Future<void> loadTransportPath() async {
    List<Stop> stops = [];
    List<Stop> allStopsAlongRoute = await ptvService.fetchStopsRoute(_transport.route!); // all stops along a given route

    // Early exit if GeoPath is empty // todo: also check if null!!!
    if (_geoPath.isEmpty || _pattern.isEmpty || allStopsAlongRoute.isEmpty) {
      return;
    }

    // Only add stops that are in the pattern, in order provided
    for (var d in _pattern) {
      stops.add(allStopsAlongRoute[allStopsAlongRoute.indexWhere((stop) => stop.id == d.stopId)]);
    }

    List<LatLng> stopPositions = [];
    LatLng chosenStopPositionAlongGeoPath = _stopPosition;
    List<LatLng> newGeoPath = [];

    for (var stop in stops) {
      var pos = LatLng(stop.latitude!, stop.longitude!);
      stopPositions.add(pos);
    }

    GeoPathAndStops geoPathAndStops = await transportPathUtils.addStopsToGeoPath(_geoPath, _stopPosition);

    newGeoPath = geoPathAndStops.geoPathWithStops;
    chosenStopPositionAlongGeoPath = geoPathAndStops.stopPositionAlongGeoPath;

    bool isReverseDirection = GeoPathUtils.reverseDirection(newGeoPath, stopPositions);

    PolyLineMarkers polyLineMarkers = await transportPathUtils.setMarkers(
      _markers,
      stopPositions,
      _stopPosition,
      chosenStopPositionAlongGeoPath,
      true,
    );

    Set<Marker> largeRouteMarkers = polyLineMarkers.largeMarkers;
    Set<Marker> smallRouteMarkers = polyLineMarkers.smallMarkers;
    Marker selectedStopMarker = polyLineMarkers.stopMarker;

    _markers = {..._markers, ...largeRouteMarkers, ...smallRouteMarkers};
    _markers.add(selectedStopMarker);

    _polyLines = await transportPathUtils.loadRoutePolyline(
      _transport.route!.colour!,
      newGeoPath,
      chosenStopPositionAlongGeoPath,
      true,
      isReverseDirection
    );

    setState(() {
    });
  }

  Future<void> _onDepartureTapped(Departure departure, Transport transport) async {
    setState(() {
      widget.arguments.searchDetails!.departure = departure;
      _isDepartureSelected = true;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(target: _center, zoom: _zoom),
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              polylines: _polyLines,
            ),
          ),


          Positioned(
            top: 40,
            left: 15,
            child: GestureDetector(
              onTap: () {
                if (_isDepartureSelected) {
                  setState(() {
                    _isDepartureSelected = false;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: BackButtonWidget(),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.26,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                child: _isDepartureSelected
                  ? DepartureDetailsSheet(arguments: widget.arguments, scrollController: scrollController)
                  : TransportDetailsSheet(arguments: widget.arguments, scrollController: scrollController, onDepartureTapped: _onDepartureTapped,)
              );
            },
          ),
        ],
      ),
      // Only call updateMainPage when necessary (e.g., when adding a new route)
      bottomNavigationBar: BottomNavigation(
        currentIndex: 2, // Search page is index 2
        updateMainPage: null,
      ),
    );
  }
}