// Home Widget
import 'dart:convert';
import 'dart:io';
import 'package:flutter_project/domain/trip.dart';
import 'package:home_widget/home_widget.dart';

import 'add_screens/utility/trip_utils.dart';

class HomeWidgetService {
  late bool isMobile;    // Android or iOS

  String appGroupId = "group.melbournePTWidget";
  String iosWidgetName = "MelbournePTWidget";
  String androidWidgetName = "MelbournePTWidget";
  String dataKey = "data_from_flutter";

  // Initialise home widgets
  Future<void> initialiseHomeWidget() async {
    // print(" (home_widget_service.dart -> initialiseHomeWidget() ) -- platform: ${Platform.operatingSystem}");
    if (Platform.isIOS || Platform.isAndroid) {
      isMobile = true;
      await HomeWidget.setAppGroupId(appGroupId);
    }
    else {
      isMobile = false;
    }
  }

// Send necessary JSON Data to Widget
  Future<void> sendWidgetData(List<Trip> transportList) async {
    print("( home_widget_service.dart -> sendWidgetData() ) -- isMobile=$isMobile");
    if (isMobile == true) {
      try {
        final optimisedData = getOptimisedData(transportList);
        final data = JsonEncoder.withIndent('  ').convert(optimisedData);

        // print("( home_widget_service.dart -> sendWidgetData() ) -- Data Size: ${getDataSize(data)}KB");
        // print("( home_widget_service.dart -> sendWidgetData() ) -- Sending JSON Data:\n $data");

        await HomeWidget.saveWidgetData(dataKey, data);

        // Call to update homescreen widget (consider making this its own function)
        await HomeWidget.updateWidget(
          iOSName: iosWidgetName,
          androidName: androidWidgetName,
        );
      } catch (e) {
        print(
            "( home_widget_service.dart -> sendWidgetData() ) -- Error sending widget data");
      }
    }
    else {
      print("Not on mobile device, cannot send data. (isMobile = $isMobile)");
    }
  }

  // Reduces the fields in the Transport class to what's needed in the Widget Design
  List<Map<String, dynamic>> getOptimisedData(List<Trip> transportList) {
    return transportList.map((transport) {
      return {
        'uniqueID': transport.uniqueID ?? "No uniqueID",
        'routeType': {'name': transport.route?.type.name ?? "No routeType"},
        'stop': {'name': transport.stop?.name ?? "No stop"},
        'route': {
          'label': TripUtils.getLabel(transport.route, transport.route?.type.name) ?? "No route",
          'colour': transport.route?.colour ?? "No colour",
          'textColour': transport.route?.textColour ?? "No text colour",
        },
        'direction': {'name': transport.direction?.name ?? "No direction"},
        'departures': (transport.departures?.take(3).toList())?.map((d) => {
          'departureTime': d.estimatedDepartureTime ?? d.scheduledDepartureTime,
          'hasLowFloor': d.hasLowFloor,
          'platformNumber': d.platformNumber,
          'statusColour': TripUtils.getStatusColor(d),
          'timeString': TripUtils.getTimeString(d),
        })
            .toList() ??
            []
      };
    }).toList();
  }

  // Calculate Size of Data in Kilobytes
  double getDataSize(String data) {
    final dataBytes = utf8.encode(data);
    double kbDataSize = dataBytes.length / 1024;
    // print("( home_widget_service.dart -> logDataSize ) -- Data Size: $kbDataSize KB");
    return kbDataSize;
  }
}