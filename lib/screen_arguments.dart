// Arguments for the AddScreens

import 'package:flutter/cupertino.dart';
import 'package:flutter_project/domain/trip.dart';

class ScreenArguments {
  Trip? trip;    // data for new Trip option
  VoidCallback callback;  // function to be called from child screen

  ScreenArguments(this.callback);
  ScreenArguments.withTrip(this.trip, this.callback);
}
