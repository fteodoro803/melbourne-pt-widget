import 'package:flutter/foundation.dart';
import 'package:flutter_project/screen_arguments.dart';

class DevTools {

  // Prints the current Screen State
  void printScreenState(String screenName, ScreenArguments arguments) {
    if (kDebugMode) {
      String transportDetails = arguments.transport.toString(); // Get the transport details as a string

      // Format transport details to indent each line
      String indentedTransportDetails = transportDetails.split('\n').map((line) => '\t\t$line').join('\n');


      print("Screen: $screenName\n"
        "Arguments: {\n"
          "\tTransport:\n$indentedTransportDetails"
        "}");
    }
  }

}