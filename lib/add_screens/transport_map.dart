import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/add_screens/transport_details_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../geopath_utils.dart';
import '../ptv_info_classes/stop_info.dart';
import '../screen_arguments.dart';
import '../widgets/departures_list.dart';
import '../ptv_service.dart';
import '../ptv_info_classes/departure_info.dart';
import '../time_utils.dart';
import '../transport.dart';

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
  late LatLng? initialMapCenter;
  late double? initialMapZoom;

  // Google Maps controller and center position
  late GoogleMapController mapController;
  late LatLng _center = const LatLng(-37.813812122509205, 144.96358311072478);
  late double _zoom = 13;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late List<LatLng> _geopath = [];
  late List<Stop> _stops = [];
  List<LatLng> _stopsAlongGeopath = [];

  @override
  void initState() {
    super.initState();
    transport = widget.arguments.transport;

    initialMapCenter = widget.arguments.mapCenter;
    initialMapZoom = widget.arguments.mapZoom;

    if (initialMapCenter != null) {
      _center = initialMapCenter!;
    } else if (transport.stop?.latitude != null && transport.stop?.longitude != null) {
      _center = LatLng(transport.stop!.latitude!, transport.stop!.longitude!);
    }

    if (initialMapZoom != null) {
      _zoom = initialMapZoom!;
    }
  }

  Future<void> loadTransportPath() async {

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
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                child: TransportDetailsSheet(arguments: widget.arguments, scrollController: scrollController)
              );
            },
          ),
        ],
      ),
    );
  }
}