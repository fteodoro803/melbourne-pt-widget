// Arguments for the AddScreens

import 'package:flutter/cupertino.dart';
import 'package:flutter_project/domain/trip.dart';

class ScreenArguments {
  Transport? transport;    // data for new Transport option
  VoidCallback callback;  // function to be called from child screen

  ScreenArguments(this.callback);
  ScreenArguments.withTransport(this.transport, this.callback);
}
