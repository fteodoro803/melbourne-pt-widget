import 'dart:io';

import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/database/helpers/gtfs_route_helpers.dart';
import 'package:flutter_project/database/helpers/gtfs_trip_helpers.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

/* GTFS Steps
- Getting GTFS Datasets (GTFS Route, GTFS Shapes)
1. todo: figure this part out (setup a server, OR use github actions) https://claude.ai/chat/b0dad283-a1ad-4c19-81cc-493659c7185d

- Mapping GTFS to PTV (Locations)
1. Get GTFS Routes (route_id)
2. Get GTFS Trips (trip_id, route_id, direction_id)

- GeoPath
1. Get GTFS Shapes (shape_id)
2. Get GTFS Trips(trip_id, shape_id, route_id)
*/

class GtfsService {
  String routesFilePath = "lib/dev/routes.txt";

  /// Adds GTFS Schedule data to database
  Future<void> initialise() async {
    try {
      // final routesFile = File("lib/dev/routes.txt");
      // final routesFileContents = await routesFile.readAsString();
      // print(routesFileContents);

      csvToMapList(routesFilePath);
    }
    catch (e) {
      print("Error $e");
    }
  }


  /// Converts CSV to Map
  Future<List<Map<String, dynamic>>> csvToMapList(String filePath) async {
    List<Map<String, dynamic>> mapList = [];

    final file = File(filePath);
    final content = await file.readAsString();

    List<List<dynamic>> rows = CsvToListConverter().convert(content);
    final headers = rows.first.map((c) => c.toString()).toList();
    final dataRows = rows.skip(1);    // skips the header row

    // Creates a Map with headers as keys, and rows as values, and adds to list
    for (var row in dataRows) {
      final mappedRow = Map.fromIterables(headers, row);
      mapList.add(mappedRow);
    }

    return mapList;
  }
}
