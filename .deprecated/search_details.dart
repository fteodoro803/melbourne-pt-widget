import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchDetails {
  LatLng? markerPosition;
  String? address;

  int? distance = 300;
  String? transportType = "all";

  bool? isSheetExpanded = false;

  // Progressively narrowing down the search
  List<Stop>? stops = [];
  Stop? stop;
  pt_route.Route? route;
  List<Transport>? transportList = [];
  Transport? transport;
  Departure? departure;

  SearchDetails();
  SearchDetails.withRoute(this.route);
  SearchDetails.withTransport(this.transport);
}