// Arguments for the AddScreens

import 'dart:ui';
import 'package:flutter_project/transport.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ScreenArguments {
  Transport transport;    // data for new Transport option
  VoidCallback callback;  // function to be called from child screen
  String transportType;
  LatLng markerPosition;

  ScreenArguments(this.transport, this.callback, this.transportType, this.markerPosition);
}
