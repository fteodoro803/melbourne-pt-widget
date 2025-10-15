// Arguments for the AddScreens

import 'package:flutter/cupertino.dart';
import 'package:flutter_project/dev/location.dart';
import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/domain/trip.dart';

class ScreenArguments {
  Trip? trip; // data for new Trip option
  RouteType? selectedRouteType;
  VoidCallback callback; // function to be called from child screen
  Location? testLocation;

  ScreenArguments(this.callback);
  ScreenArguments.withTrip(this.trip, this.callback);
}
