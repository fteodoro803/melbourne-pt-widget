import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/utility/map_utils.dart';
import 'package:flutter_project/add_screens/widgets/screen_widgets.dart';
import 'package:flutter_project/add_screens/widgets/transport_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;
import '../ptv_service.dart';

class RouteDetailsScreen extends StatefulWidget {
  final pt_route.Route route;

  RouteDetailsScreen({
    super.key,
    required this.route
  });

  @override
  _RouteDetailsScreenState createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {

  late pt_route.Route _route;
  List<Stop> _stops = [];
  List<LatLng> _geoPath = [];

  PtvService ptvService = PtvService();
  TransportPathUtils transportPathUtils = TransportPathUtils();

  Set<Marker> _markers = {};
  Set<Polyline> _polyLines = {};
  Set<Marker> _routeMarkers = {};
  late Marker _firstMarker;
  late Marker _lastMarker;

  late GoogleMapController _mapController;

  final double _mapZoom = 14;
  final LatLng _center = const LatLng(-37.813812122509205,
      144.96358311072478); //todo: Change based on user's location;


  Future<void> getStopsAlongRoute() async {
    List<Stop> stops = await ptvService.fetchStopsRoute(_route);
    List<LatLng> geoPath = await ptvService.fetchGeoPath(_route);

    setState(() {
      _stops = stops;
      _geoPath = geoPath;
    });

    _loadTransportPath();
  }

  Future<void> setMapView() async {

  }

  Future<void> _loadTransportPath() async {

    List<LatLng> stopPositions = [];

    for (var stop in _stops) {
      var pos = LatLng(stop.latitude!, stop.longitude!);
      stopPositions.add(pos);
    }

    GeoPathAndStops geoPathAndStops = await transportPathUtils.addStopsToGeoPath(_geoPath, allStopPositions: stopPositions);

    List<LatLng> newGeoPath = geoPathAndStops.geoPathWithStops;
    stopPositions = geoPathAndStops.stopsAlongGeoPath; // stops along route aligned with geoPath

    PolyLineMarkers polyLineMarkers = await transportPathUtils.setMarkers(
      _markers,
      stopPositions,
      false,
    );

    _routeMarkers = polyLineMarkers.largeMarkers;
    _firstMarker = polyLineMarkers.firstMarker!;
    _lastMarker = polyLineMarkers.lastMarker!;

    _markers = {..._markers, ..._routeMarkers};
    _markers.add(_firstMarker);

    _markers.add(_lastMarker);

    _polyLines = await transportPathUtils.loadRoutePolyline(
      _route.colour!,
      newGeoPath,
      false,
      false
    );

    setState(() {
    });
  }

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    // _center = const LatLng(-37.813812122509205,
    //     144.96358311072478); //todo: Change based on user's location
    // _mapZoom = 15;

    getStopsAlongRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition:
                CameraPosition(target: _center, zoom: _mapZoom),
              markers: _markers,
              polylines: _polyLines,
            ),
          ),
          Positioned(
            top: 40,
            left: 15,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);

              },
              child: BackButtonWidget(),
            ),
          ),
          DraggableScrollableSheet(
            controller: DraggableScrollableController(),
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
                child: Column(
                  children: [
                    HandleWidget(),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        controller: scrollController,
                        physics: ClampingScrollPhysics(),
                        children: [
                          RouteWidget(route: _route, scrollable: false,),
                          Text(_route.name),
                          Divider(),
                          Card(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: Column(
                              children: _stops.map((stop) {
                                return ListTile(
                                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(stop.name, style: TextStyle(fontSize: 16)),
                                  trailing: Icon(Icons.keyboard_arrow_right),
                                );
                              }).toList(),
                            ),
                          ),
                        ]
                      )
                    ),
                    Text("Empty"),
                  ],
                )
              );
            }
          )
        ],
      ),
      // bottomNavigationBar: BottomNavigation(
      // currentIndex: 2,
      // updateMainPage: null,
      // ),
    );
  }
}