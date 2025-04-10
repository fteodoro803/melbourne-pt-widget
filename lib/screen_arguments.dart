// Arguments for the AddScreens

import 'package:flutter/cupertino.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchDetails {
  LatLng? markerPosition;
  String? address;

  int? distance;
  String? transportType;

  bool? isSheetExpanded = false;

  Stop? stop;
  pt_route.Route? route;
  Transport? transport;
  Departure? departure;

  List<Stop>? stops;
  List<Transport>? directions;

  SearchDetails();
}

class ScreenArguments {
  Transport? transport;    // data for new Transport option
  VoidCallback callback;  // function to be called from child screen

  ScreenArguments(this.callback);
  ScreenArguments.withTransport(this.transport, this.callback);

  // ScreenArguments.withSearchDetails(this.searchDetails);
}
