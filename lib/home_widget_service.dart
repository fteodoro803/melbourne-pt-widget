// Home Widget
import 'dart:convert';

import 'package:flutter_project/transport.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {

  String appGroupId = "group.melbournePTWidget";
  String iosWidgetName = "MelbournePTWidget";
  String androidWidgetName = "MelbournePTWidget";
  String dataKey = "data_from_flutter";

// Send necessary JSON Data to Widget
  void sendWidgetData(List<Transport> transportList) async {
    try {
      final optimisedData = transportList.map((transport) {
        // Includes fields needed by the Swift Transport class
        return {
          'uniqueID': transport.uniqueID ?? "No uniqueID",
          'routeType': {
            'name': transport.routeType?.name ?? "No routeType"
          },
          'stop': {
            'name': transport.stop?.name ?? "No stop"
          },
          'route': {
            'number': transport.route?.number ?? "No route"
          },
          'direction': {
            'name': transport.direction?.name ?? "No direction"
          },
          'departures': transport.departures?.map((d) =>
          {
            'scheduledDepartureTime': d.scheduledDepartureTime,
            'estimatedDepartureTime': d.estimatedDepartureTime
          }).toList() ?? []
        };
      }).toList();

      final data = JsonEncoder.withIndent('  ').convert(optimisedData);

      print("( main.dart -> sendWidgetData() ) -- Sending JSON Data:\n $data");

      await HomeWidget.saveWidgetData(dataKey, data);

      // Update widget after saving data
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        androidName: androidWidgetName,
      );
    }
    catch (e) {
      print("( main.dart -> sendWidgetData() ) -- Error sending widget data");
    }
  }

  // Initialise home widgets
  void initialiseHomeWidget() async {
    HomeWidget.setAppGroupId(appGroupId);
  }
}