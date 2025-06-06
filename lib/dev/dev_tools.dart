import 'package:flutter/foundation.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/domain/trip.dart';

class DevTools {
  bool isEnabled = false;

  // Prints the current Screen State
  void printScreenState(String screenName, ScreenArguments arguments) {

    if (kDebugMode && isEnabled) {
      String transportDetails = arguments.trip.toString(); // Get the transport details as a string

      // Format transport details to indent each line
      String indentedTransportDetails = transportDetails.split('\n').map((line) => '\t\t$line').join('\n');


      print("Screen: $screenName\n"
        "Arguments: {\n"
          "\tTransport:\n$indentedTransportDetails"
        "}");
    }
  }

  void printTransport(Trip transport) {
    if (kDebugMode) {
      String transportDetails = transport
          .toString(); // Get the transport details as a string

      // Format transport details to indent each line
      String indentedTransportDetails = transportDetails.split('\n').map((
          line) => '\t\t$line').join('\n');


      print("Transport Details:\n"
          "Arguments: {\n"
          "\tTransport:\n$indentedTransportDetails"
          "}");
    }
  }

  void printTransportList(List<Trip> transportList) {
    if (transportList.isEmpty) {
      if (kDebugMode) {
        print("TransportList is empty");
      }
    }

    for (int i=0; i<transportList.length; i++) {
      if (kDebugMode) {
        print("TransportList[$i]:");
        printTransport(transportList[i]);
      }
    }
  }

}