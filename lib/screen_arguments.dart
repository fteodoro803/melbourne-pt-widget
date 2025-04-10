// Arguments for the AddScreens

import 'package:flutter/cupertino.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchDetails {
  LatLng? markerPosition;
  int distance = 300;
  String transportType = "all";
  bool isSheetExpanded = false;
  TextEditingController locationController;

  Stop? stop;
  pt_route.Route? route;
  Departure? departure;

  List<Stop> stops = [];
  List<pt_route.Route> routes = [];
  List<Transport> directions = [];

  SearchDetails(this.locationController);
}

class ScreenArguments {
  Transport transport;    // data for new Transport option
  VoidCallback callback;  // function to be called from child screen
  SearchDetails? searchDetails;

  ScreenArguments(this.transport, this.callback);
  ScreenArguments.withSearchDetails(this.transport, this.callback, this.searchDetails);

  // ScreenArguments.withSearchDetails(this.searchDetails);
}
