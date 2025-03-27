import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/departures_list.dart';
import '../ptv_service.dart';
import '../ptv_info_classes/departure_info.dart';
import '../time_utils.dart';
import '../transport.dart';

enum ResultsFilter {
  airConditioning(name: "Air Conditioning"),
  lowFloor(name: "Low Floor");

  final String name;

  const ResultsFilter({required this.name});
}

class TransportDetailsScreen extends StatefulWidget {
  final Transport transport;

  TransportDetailsScreen({required this.transport});

  @override
  _TransportDetailsScreenState createState() => _TransportDetailsScreenState();
}

class _TransportDetailsScreenState extends State<TransportDetailsScreen> {
  late Transport transport;
  Timer? _timer;

  // Google Maps controller and center position
  late GoogleMapController mapController;
  late LatLng _center;

  Set<Marker> _markers = {};

  Set<ResultsFilter> filters = <ResultsFilter>{};

  @override
  void initState() {
    super.initState();
    transport = widget.transport;

    if (transport.stop?.latitude != null && transport.stop?.longitude != null) {
      _center = LatLng(transport.stop!.latitude! as double, transport.stop!.longitude as double);
    } else {
      _center = const LatLng(-37.813812122509205, 144.96358311072478);
    }

    _addMarker();

    // Update departures when the screen is initialized
    updateDepartures();

    // Set up a timer to update departures every 30 seconds
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      updateDepartures();
    });

    // Load the route polyline
    // _loadRoutePolyline();
  }

  // Function to load the route polyline
  // void _loadRoutePolyline() {
  //   // Example list of coordinates representing the route
  //   List<LatLng> routeCoordinates = [
  //     LatLng(-37.813612, 144.963058),
  //     LatLng(-37.814612, 144.964058),
  //     LatLng(-37.815612, 144.965058),
  //   ];
  //
  //   setState(() {
  //     _polylines.add(Polyline(
  //       polylineId: PolylineId('route_polyline'),
  //       color: Colors.blue,
  //       width: 5,
  //       points: routeCoordinates,
  //     ));
  //   });
  // }

  void _addMarker() {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('center_marker'),
        position: _center, // The position where the dot will appear
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Set the color of the dot (red in this case)
      ));
    });
  }

  // Update Departures
  Future<void> updateDepartures() async {
    String? routeType = transport.routeType?.type.id.toString();
    String? stopId = transport.stop?.id;
    String? directionId = transport.direction?.id;
    String? routeId = transport.route?.id;

    // Early exit if any of the prerequisites are null
    if (routeType == null || stopId == null || directionId == null || routeId == null) {
      return;
    }

    // Gets Departures and saves to instance
    PtvService ptvService = PtvService();
    List<Departure>? updatedDepartures = await ptvService.fetchDepartures(
        routeType, stopId, routeId, directionId: directionId
    );

    setState(() {
      transport.departures = updatedDepartures;
    });
    }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              initialCameraPosition: CameraPosition(target: _center, zoom: 16),
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              // polylines: _polylines,
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
                  color: Colors.white,
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
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          ),

          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        height: 5,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_pin, size: 16),
                              SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  transport.stop?.name ?? "No Data",
                                  style: TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),

                          Row(
                            children: [
                              Image.asset(
                                "assets/icons/PTV ${transport.routeType?.type.name} Logo.png",
                                width: 40,
                                height: 40,
                              ),
                              SizedBox(width: 8),

                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: transport.route?.colour != null
                                      ? ColourUtils.hexToColour(transport.route!.colour!)
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  // transport.route?.number ?? "No Data",
                                  transport.routeType?.type.name == "train" ||
                                      transport.routeType?.type.name == "vLine"
                                      ? transport.direction?.name ?? "No Data"
                                      : transport.route?.number ?? "No Data",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: transport.route?.textColour != null
                                        ? ColourUtils.hexToColour(transport.route!.textColour!)
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Divider(),
                          Wrap(
                            spacing: 5.0,
                            children: ResultsFilter.values.map((ResultsFilter result) {
                              return FilterChip(
                                label: Text(result.name),
                                selected: filters.contains(result),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      filters.add(result);
                                    } else {
                                      filters.remove(result);
                                    }
                                  });
                                }
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Upcoming Departures",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DeparturesList(departuresLength: 30, transport: transport),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}