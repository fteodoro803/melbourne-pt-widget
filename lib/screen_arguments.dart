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
  String transportType = "all"; //  remove this
  bool isSheetExpanded = false;
  TextEditingController locationController; // remove this

  Stop? stop; // when stop is selected
  pt_route.Route? route; // when stop is selected
  Transport? transport; // when transport is selected
  Departure? departure; // when departure is selected

  List<Stop> stops = []; // when location is selected
  List<pt_route.Route> routes = []; // remove this
  List<Transport> directions = []; // when stop is selected

  SearchDetails(this.locationController);
}

class ScreenArguments {
  Transport? transport;    // data for new Transport option
  VoidCallback callback;  // function to be called from child screen
  SearchDetails? searchDetails;

  ScreenArguments(this.transport, this.callback);
  ScreenArguments.withSearchDetails2(this.callback, this.searchDetails);
  ScreenArguments.withSearchDetails(this.transport, this.callback, this.searchDetails);

  // ScreenArguments.withSearchDetails(this.searchDetails);
}
