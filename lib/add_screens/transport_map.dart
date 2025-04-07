import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/departure_details_sheet.dart';
import 'package:flutter_project/add_screens/transport_details_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utility/geopath_utils.dart';
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
  late Transport transport;
  bool _isDepartureSelected = false;

  // Google Maps controller and center position
  late GoogleMapController mapController;
  late LatLng _center = const LatLng(-37.813812122509205, 144.96358311072478);
  late double _zoom = 13;

  late LatLng _stopPosition;
  late LatLng _stopPositionAlongGeopath;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late List<LatLng> _geopath = [];
  late List<Stop> _stops = [];
  List<LatLng> _stopsAlongGeopath = [];

  PtvService ptvService = PtvService();
  TransportPathUtils transportPathUtils = TransportPathUtils();

  @override
  void initState() {
    super.initState();
    transport = widget.arguments.transport;

    if (transport.stop?.latitude != null && transport.stop?.longitude != null) {
      _center = LatLng(transport.stop!.latitude!, transport.stop!.longitude!);
    }

    // loadTransportPath();
  }

  // Future<void> loadTransportPath() async {
  //   _stopPosition = LatLng(transport.stop!.latitude!, transport.stop!.longitude!);
  //   _stopPositionAlongGeopath = _stopPosition;
  //
  //   _geopath = await ptvService.fetchGeoPath(transport.route!);
  //   _stops = await ptvService.fetchStopsRoute(transport.route!, direction: transport.direction!);
  //   GeoPathAndStops geoPathAndStops = await transportPathUtils.addStopsToGeoPath(_stops, _geopath, _stopPosition);
  //
  //   _geopath = geoPathAndStops.geopath;
  //   _stopsAlongGeopath = geoPathAndStops.stopsAlongGeoPath;
  //   _stopPositionAlongGeopath = geoPathAndStops.stopPositionAlongGeoPath;
  //
  //   bool isReverseDirection = GeoPathUtils.reverseDirection(_geopath, _stops);
  //
  //   _markers = await transportPathUtils.setMarkers(
  //       _markers,
  //       _stopsAlongGeopath,
  //       _stopPositionAlongGeopath,
  //       true,
  //       isReverseDirection,
  //   );
  //   _polylines = await transportPathUtils.loadRoutePolyline(
  //       transport,
  //       _geopath,
  //       _stopPositionAlongGeopath,
  //       true,
  //       isReverseDirection,
  //   );
  //
  //   setState(() {
  //   });
  // }

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
              polylines: _polylines,
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