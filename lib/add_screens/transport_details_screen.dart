import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../geopath_utils.dart';
import '../ptv_info_classes/stop_info.dart';
import '../screen_arguments.dart';
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
  final ScreenArguments? arguments;
  final Transport transport;

  TransportDetailsScreen({
    super.key,
    required this.transport,
    this.arguments,
  });

  @override
  _TransportDetailsScreenState createState() => _TransportDetailsScreenState();
}

class _TransportDetailsScreenState extends State<TransportDetailsScreen> {
  late Transport transport;
  late LatLng? initialMapCenter;
  late double? initialMapZoom;
  Timer? _timer;

  PtvService ptvService = PtvService();

  // Google Maps controller and center position
  late GoogleMapController mapController;
  late LatLng _stopPosition;
  late LatLng _stopPositionAlongGeopath = _stopPosition;
  late LatLng _center = const LatLng(-37.813812122509205, 144.96358311072478);
  late double _zoom = 13;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late List<LatLng> _geopath = [];
  late List<Stop> _stops = [];
  List<LatLng> _stopsAlongGeopath = [];

  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? _customMarkerIconFuture;
  BitmapDescriptor? _customMarkerIconPrevious;
  BitmapDescriptor? _customStopMarkerIcon;

  Set<ResultsFilter> filters = <ResultsFilter>{};

  @override
  void initState() {
    super.initState();
    transport = widget.transport;

    initialMapCenter = widget.arguments?.mapCenter;
    initialMapZoom = widget.arguments?.mapZoom;

    print("Stop latitude: ${transport.stop!.latitude}");
    print("Stop longitude: ${transport.stop!.longitude}");
    _stopPosition = LatLng(transport.stop!.latitude!, transport.stop!.longitude!);

    if (initialMapCenter != null) {
      _center = initialMapCenter!;
    } else if (transport.stop?.latitude != null && transport.stop?.longitude != null) {
      _center = LatLng(transport.stop!.latitude!, transport.stop!.longitude!);
    }

    if (initialMapZoom != null) {
      _zoom = initialMapZoom!;
    }

    // _setMarkers();
    _loadRoutePolyline();

    // Update departures when the screen is initialized
    updateDepartures();

    // Set up a timer to update departures every 30 seconds
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      updateDepartures();
    });
  }

  Future<void> _addStopsToGeoPath() async {
    setState(() {
      for (var stop in _stops) {
        var stopPosition = LatLng(stop.latitude!, stop.longitude!);
        var closestPoint = GeoPathUtils.findClosestPoint(stopPosition, _geopath);
        _stopsAlongGeopath.add(closestPoint);

        // Find the correct index to insert the closestPoint
        if (!_geopath.contains(closestPoint) && stopPosition == _stopPosition) {
          _stopPositionAlongGeopath = closestPoint;

          // Find the two closest points in _geopath to insert between them
          int insertionIndex = 0;
          for (int i = 0; i < _geopath.length - 1; i++) {
            LatLng pointA = _geopath[i];
            LatLng pointB = _geopath[i + 1];

            // If closestPoint is between pointA and pointB
            if (GeoPathUtils.isBetween(closestPoint, pointA, pointB)) {
              insertionIndex = i + 1;
              break;
            }
          }

          // Insert the closest point at the correct position
          _geopath.insert(insertionIndex, closestPoint);
        }
      }
    });
  }

  // Function to load the route polyline
  Future<void> _loadRoutePolyline() async {
    await _setMarkers();

    int closestIndex = _geopath.indexOf(_stopPositionAlongGeopath);

    // Separate the coordinates into previous and future journey                  ADD IMPLEMENTATION FOR REVERSE DIRECTION !!!
    List<LatLng> previousRoute = _geopath.sublist(0, closestIndex + 1);
    List<LatLng> futureRoute = _geopath.sublist(closestIndex);

    setState(() {
      // Add polyline for previous journey
      _polylines.add(Polyline(
        polylineId: PolylineId('previous_route_polyline'),
        color: Color(0xFFB6B6B6),
        width: 6,
        points: previousRoute,
      ));

      // Add polyline for future journey
      _polylines.add(Polyline(
        polylineId: PolylineId('future_route_polyline'),
        color: ColourUtils.hexToColour(transport.route!.colour!),
        width: 9,
        points: futureRoute,
      ));
    });
  }

  Future<void> _setMarkers() async {
    _geopath = await ptvService.fetchGeoPath(transport.route!);
    _stops = await ptvService.fetchStopsAlongDirection(transport.route!, transport.direction!);
    await _addStopsToGeoPath();

    _customMarkerIconPrevious = await getResizedImage("assets/icons/Marker Filled.png", 8, 8);
    _customMarkerIconFuture = await getResizedImage("assets/icons/Marker Filled.png", 10, 10);
    _customMarkerIcon = _customMarkerIconPrevious;
    _customStopMarkerIcon = await getResizedImage("assets/icons/Marker Filled.png", 16, 16);

    setState(() {
      for (var stop in _stopsAlongGeopath) {
        if (stop == _stopPositionAlongGeopath) {
          _customMarkerIcon = _customMarkerIconFuture;
          continue;
        }
        _markers.add(Marker(
          markerId: MarkerId("$stop"),
          position: stop,
          icon: _customMarkerIcon!,
        ));
      }
      // for (var stop in _stops) {
      //   _markers.add(Marker(
      //     markerId: MarkerId(stop.id),
      //     position: LatLng(stop.latitude!, stop.longitude!),
      //     icon: _customMarkerIconPrevious!,
      //   ));
      // }
      _markers.add(Marker(
        markerId: MarkerId('center_marker'),
        position: _stopPositionAlongGeopath,
        icon: _customStopMarkerIcon!,
      ));
      if (widget.arguments?.searchDetails.markerPosition != null) {
        _markers.add(Marker(
          markerId: MarkerId('position'),
          position: widget.arguments!.searchDetails.markerPosition!,
      ));
      }
    });
  }

  Future<BitmapDescriptor> getResizedImage(String assetPath, double width, double height) async {
    // Load the image from assets
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List();

    // Decode the image
    final ui.Image image = await decodeImageFromList(Uint8List.fromList(bytes));

    // Resize the image using a canvas
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder, Rect.fromPoints(Offset(0.0, 0.0), Offset(width, height)));
    final Paint paint = Paint();

    // Scale the image on the canvas
    canvas.drawImageRect(image, Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()), Rect.fromLTRB(0, 0, width, height), paint);

    // Convert to an image
    final ui.Image resizedImage = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());

    // Convert to byte data
    final ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    // Return the resized BitmapDescriptor
    return BitmapDescriptor.bytes(resizedBytes);
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

  bool get lowFloorFilter => filters.contains(ResultsFilter.lowFloor);
  bool get airConditionerFilter => filters.contains(ResultsFilter.airConditioning);

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
                              SizedBox(width: 10),

                              if (transport.routeType?.type.name != "train" && transport.routeType?.type.name != "vLine")
                                Text(
                                  transport.direction?.name ?? "No Data",
                                  style: TextStyle(
                                    fontSize: 18,
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: DeparturesList(departuresLength: 30, transport: transport, lowFloorFilter: lowFloorFilter, airConditionerFilter: airConditionerFilter,),
                      ),
                    ),
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