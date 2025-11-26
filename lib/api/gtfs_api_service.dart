import 'package:http/http.dart' as http;
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GtfsApiService {
  late String apiKey;

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

  /// Fetch tram trip updates
  Future<FeedMessage> tramTripUpdates() async {
    final String tramTripUpdatesUrl =
        "https://api.opendata.transport.vic.gov.au/opendata/public-transport/gtfs/realtime/v1/tram/trip-updates";
    try {
      final response = await http.get(
        Uri.parse(tramTripUpdatesUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      } else {
        throw Exception(
            "( gtfs_api_service.dart -> getTramTripUpdates ) -- Failed to load trip updates: error code ${response.statusCode}; request: ${response.request}");
      }
    } catch (e) {
      throw Exception(
          "( gtfs_api_service.dart -> getTramTripUpdates ) -- Error fetching trip updates $e");
    }
  }

  /// Fetch tram service alerts
  Future<FeedMessage> tramServiceAlerts() async {
    final String serviceAlertsUrl =
        "https://api.opendata.transport.vic.gov.au/opendata/public-transport/gtfs/realtime/v1/tram/service-alerts";
    try {
      final response = await http.get(
        Uri.parse(serviceAlertsUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      } else {
        throw Exception(
            "( gtfs_api_service.dart -> getTramServiceAlerts ) -- Failed to load trip updates: error code ${response.statusCode}; request: ${response.request}");
      }
    } catch (e) {
      throw Exception(
          "( gtfs_api_service.dart -> getTramServiceAlerts ) -- Error fetching service alerts $e");
    }
  }

  /// Fetch vehicle positions
  Future<FeedMessage> tramVehiclePositions() async {
    final String vehiclePositionsUrl =
        "https://api.opendata.transport.vic.gov.au/opendata/public-transport/gtfs/realtime/v1/tram/vehicle-positions";
    try {
      final response = await http.get(
        Uri.parse(vehiclePositionsUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      } else {
        throw Exception(
            "( gtfs_api_service.dart -> getTramVehiclePositions ) -- Failed to load vehicle positions: error code: ${response.statusCode}; response: ${response.toString()}");
      }
    } catch (e) {
      throw Exception(
          "( gtfs_api_service.dart -> getTramVehiclePositions ) -- Error fetching vehicle positions $e");
    }
  }
}
