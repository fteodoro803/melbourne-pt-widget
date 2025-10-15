import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

class GtfsApiService {
  final String gtfsKey; // todo: store as an environment variable or something

  /// Creates a GtfsApiService object, with an optional GlobalConfiguration
  GtfsApiService({GlobalConfiguration? config})
      : gtfsKey = (config ?? GlobalConfiguration()).get("gtfsKey");

  Map<String, String> get _headers => {
        'KeyId':
            gtfsKey, // todo: find a way to check  if these are all there at startup, and disable functionality if needed
        'accept': '*/*',
      };

  // Fetch tram trip updates
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

  // Fetch tram service alerts
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

  // Fetch vehicle positions
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
            "( gtfs_api_service.dart -> getTramVehiclePositions ) -- Failed to load vehicle positions: error code: ${response.statusCode}; responmse: ${response.toString()}");
      }
    } catch (e) {
      throw Exception(
          "( gtfs_api_service.dart -> getTramVehiclePositions ) -- Error fetching vehicle positions $e");
    }
  }
}
