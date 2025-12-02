import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GtfsApiService {
  late String apiKey;
  final String realtimeUrl = "https://api.opendata.transport.vic.gov.au/opendata/public-transport/gtfs/realtime/v1";
  final String scheduleUrl = "https://gtfs-schedule-updater-637183453918.australia-southeast2.run.app";

  // Constructor
  GtfsApiService() {
    apiKey = dotenv.env["GTFS_API_KEY"] ?? "";

    if (apiKey.isEmpty) {
      throw Exception("Missing GTFS API credentials");
    }
  }

  // Headers
  Map<String, String> get _headers => {
        'KeyId':
            apiKey,
        'accept': '*/*',
      };

  /// Fetch realtime tram trip updates
  Future<FeedMessage> tramTripUpdates() async {
    final String url = "$realtimeUrl/tram/trip-updates";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      print("(gtfs_api_service.dart -> tramTripUpdates) -- Request: ${response.request}");

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      } else {
        throw Exception(
            "( gtfs_api_service.dart -> tramTripUpdates ) -- Failed to load trip updates: error code ${response.statusCode}; request: ${response.request}");
      }
    } catch (e) {
      throw Exception(
          "( gtfs_api_service.dart -> tramTripUpdates ) -- Error fetching trip updates $e");
    }
  }

  /// Fetch realtime tram service alerts
  Future<FeedMessage> tramServiceAlerts() async {
    final String url = "$realtimeUrl/tram/service-alerts";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      print("(gtfs_api_service.dart -> tramServiceAlerts) -- Request: ${response.request}");

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      } else {
        throw Exception(
            "( gtfs_api_service.dart -> tramServiceAlerts ) -- Failed to load trip updates: error code ${response.statusCode}; request: ${response.request}");
      }
    } catch (e) {
      throw Exception(
          "( gtfs_api_service.dart -> tramServiceAlerts ) -- Error fetching service alerts $e");
    }
  }

  /// Fetch realtime vehicle positions
  Future<FeedMessage> tramVehiclePositions() async {
    final String url = "$realtimeUrl/tram/vehicle-positions";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      print("(gtfs_api_service.dart -> tramVehiclePositions) -- Request: ${response.request}");

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      } else {
        throw Exception(
            "( gtfs_api_service.dart -> tramVehiclePositions ) -- Failed to load vehicle positions: error code: ${response.statusCode}; response: ${response.toString()}");
      }
    } catch (e) {
      throw Exception(
          "( gtfs_api_service.dart -> tramVehiclePositions ) -- Error fetching vehicle positions $e");
    }
  }

  /// Fetch scheduled tram routes in GTFS formatting
  Future<List<dynamic>> tramRoutes() async {
    final String url = "$scheduleUrl/routes";
    try {
      final response = await http.get(Uri.parse(url));
      print("(gtfs_api_service.dart -> tramRoutes) -- Request: ${response.request}");
      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        // print(' ( gtfs_api_service.dart -> tramRoutes ) -- Routes: \n${response.body}');
        return jsonResponse;
      }
      else {
        throw Exception(" ( gtfs_api_service.dart -> tramRoutes ) -- Failed to load gtfs tram routes: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("( gtfs_api_service.dart -> tramRoutes ) -- Error fetching tram routes $e");
    }
  }

  /// Fetch scheduled tram trips
  Future<List<dynamic>> tramTrips(String routeId) async {
    // 1. Base URL
    final String url = "$scheduleUrl/trips";

    // 2. Adding query parameters
    final Uri uri = Uri.parse(url).replace(
      queryParameters: {
        "id": routeId
      }
    );

    // 3. Fetch data
    try {
      final response = await http.get(uri);
      print("(gtfs_api_service.dart -> tramTrips) -- Request: ${response.request}");
      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        // print(" ( gtfs_api_service.dart -> tramTrips ) -- Trips for route '$routeId': ${response.body}");
        return jsonResponse;
      }
      else {
        throw Exception(" ( gtfs_api_service.dart -> tramTrips ) -- Failed to load gtfs tram trips for route $routeId: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("( gtfs_api_service.dart -> tramTrips ) -- Error fetching tram trips $e");
    }
  }

  /// Fetch scheduled tram shapes/geopaths
  Future<List<dynamic>> tramShapes(String shapeId) async {
    // 1. Base URL
    final String url = "$scheduleUrl/shapes";

    // 2. Adding query parameters
    final Uri uri = Uri.parse(url).replace(
        queryParameters: {
          "id": shapeId
        }
    );

    // 3. Fetch data
    try {
      final response = await http.get(uri);
      print("(gtfs_api_service.dart -> tramShapes) -- Request: ${response.request}");
      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        // print(" ( gtfs_api_service.dart -> tramShapes ) -- Shapes for route '$shapeId': ${response.body}");
        return jsonResponse;
      }
      else {
        throw Exception(" ( gtfs_api_service.dart -> tramShapes ) -- Failed to load gtfs tram shapes for shape $shapeId: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("( gtfs_api_service.dart -> tramShapes ) -- Error fetching tram shapes $e");
    }
  }

  Future<List<dynamic>> tramRouteShapes(String routeId) async {
    // 1. Base URL
    final String url = "$scheduleUrl/routeShapes";

    // 2. Adding query parameters
    final Uri uri = Uri.parse(url).replace(
        queryParameters: {
          "id": routeId
        }
    );

    // 3. Fetch data
    try {
      final response = await http.get(uri);
      print("(gtfs_api_service.dart -> tramRouteShapes) -- Request: ${response.request}");
      var jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        // print(" ( gtfs_api_service.dart -> tramRouteShapes ) -- Shapes for route '$routeId': ${response.body}");
        return jsonResponse;
      }
      else {
        throw Exception(" ( gtfs_api_service.dart -> tramRouteShapes ) -- Failed to load gtfs tram shapes for route $routeId: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("( gtfs_api_service.dart -> tramRouteShapes ) -- Error fetching tram shapes $e");
    }
  }
}
