import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/domain/route.dart' as pt_route;
import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/trip.dart';
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