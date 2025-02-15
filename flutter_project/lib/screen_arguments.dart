// Arguments for the AddScreens

import 'dart:ui';
import 'package:flutter_project/transport.dart';

class ScreenArguments {
  Transport transport;    // data for new Transport option
  VoidCallback callback;  // function to be called from child screen

  ScreenArguments(this.transport, this.callback);
}
