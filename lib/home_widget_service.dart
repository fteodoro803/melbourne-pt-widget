// Home Widget
import 'dart:convert';
import 'dart:io';
import 'package:flutter_project/transport.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  bool isMobile = false;    // Android or iOS

  String appGroupId = "group.melbournePTWidget";
  String iosWidgetName = "MelbournePTWidget";
  String androidWidgetName = "MelbournePTWidget";
  String dataKey = "data_from_flutter";

  // Initialise home widgets
  void initialiseHomeWidget() async {
    print(" (home_widget_service.dart -> initialiseHomeWidget() ) -- platform: ${Platform.operatingSystem}");
    if (Platform.isIOS || Platform.isAndroid) {
      isMobile = true;
      HomeWidget.setAppGroupId(appGroupId);
    }
  }

// Send necessary JSON Data to Widget
  void sendWidgetData(List<Transport> transportList) async {
    if (isMobile == true) {
      try {
        final optimisedData = transportList.map((transport) {
          // Includes fields needed by the Swift Transport class
          return {
            'uniqueID': transport.uniqueID ?? "No uniqueID",
            'routeType': {'name': transport.routeType?.name ?? "No routeType"},
            'stop': {'name': transport.stop?.name ?? "No stop"},
            'route': {
              'number': transport.route?.number ?? "No route",
              'colour': transport.route?.colour},
            'direction': {'name': transport.direction?.name ?? "No direction"},
            'departures': transport.departures
                    ?.map((d) => {
                          'scheduledDepartureTime': d.scheduledDepartureTime,
                          'estimatedDepartureTime': d.estimatedDepartureTime,
                          'hasLowFloor': d.hasLowFloor,
                        })
                    .toList() ??
                []
          };
        }).toList();

        final data = JsonEncoder.withIndent('  ').convert(optimisedData);

        print(
            "( home_widget_service.dart -> sendWidgetData() ) -- Sending JSON Data:\n $data");

        await HomeWidget.saveWidgetData(dataKey, data);

        // Update widget after saving data
        await HomeWidget.updateWidget(
          iOSName: iosWidgetName,
          androidName: androidWidgetName,
        );
      } catch (e) {
        print(
            "( home_widget_service.dart -> sendWidgetData() ) -- Error sending widget data");
      }
    }
  }
}