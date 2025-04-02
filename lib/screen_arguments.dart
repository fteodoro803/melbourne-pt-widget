// Arguments for the AddScreens

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as PTRoute;
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchDetails {
  LatLng? markerPosition;
  int distance = 300;
  String transportType = "all";
  Stop? stop;
  PTRoute.Route? route;
  TextEditingController locationController;

  List<Stop> stops;
  List<PTRoute.Route> routes;
  List<Transport> directions;

  SearchDetails(this.stops, this.routes, this.directions, this.locationController);
}

class ScreenArguments {
  Transport transport;    // data for new Transport option
  VoidCallback callback;  // function to be called from child screen
  SearchDetails? searchDetails;

  ScreenArguments(this.transport, this.callback);
  ScreenArguments.withSearchDetails(this.transport, this.callback, this.searchDetails);

  // ScreenArguments.withSearchDetails(this.searchDetails);
}
