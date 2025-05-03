import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

class GtfsApiService {
  final String subscriptionKey; // todo: store as an environment variable or something

  /// Creates a GtfsApiService object, with an optional GlobalConfiguration
  GtfsApiService({GlobalConfiguration? config})
      : subscriptionKey =
            (config ?? GlobalConfiguration()).get("Ocp-Apim-Subscription-Key");

  Map<String, String> get _headers => {
        // 'Cache-Control': 'no-cache'    // todo: figure out why this is no-cache on the site
        'Ocp-Apim-Subscription-Key': subscriptionKey,
        'Accept': 'application/x-google-protobuf',
      };

  // Fetch tram trip updates
  Future<FeedMessage> tramTripUpdates() async {
    final String tramTripUpdatesUrl = "https://data-exchange-api.vicroads.vic.gov.au/opendata/gtfsr/v1/tram/tripupdates";
    try {
      final response = await http.get(
        Uri.parse(tramTripUpdatesUrl),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      }
      else {
        throw Exception("( gtfs_api_service.dart -> getTramTripUpdates ) -- Failed to load trip updates: ${response.statusCode}");
      }
    } catch(e) {
      throw Exception("( gtfs_api_service.dart -> getTramTripUpdates ) -- Error fetching trip updates $e");
    }
  }

  // Fetch tram service alerts
  Future<FeedMessage> tramServiceAlerts() async {
    final String serviceAlertsUrl = "https://data-exchange-api.vicroads.vic.gov.au/opendata/gtfsr/v1/tram/servicealert";
    try {
      final response = await http.get(
        Uri.parse(serviceAlertsUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      }
      else {
        throw Exception("( gtfs_api_service.dart -> getTramServiceAlerts ) -- Failed to load trip updates: ${response.statusCode}");
      }
    } catch(e) {
      throw Exception("( gtfs_api_service.dart -> getTramServiceAlerts ) -- Error fetching service alerts $e");
    }
  }

  // Fetch vehicle positions
  Future<FeedMessage> tramVehiclePositions() async {
    final String vehiclePositionsUrl = "https://data-exchange-api.vicroads.vic.gov.au/opendata/gtfsr/v1/tram/vehicleposition";
    try {
      final response = await http.get(
        Uri.parse(vehiclePositionsUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Parsing protobuf response
        final feedMessage = FeedMessage.fromBuffer(response.bodyBytes);
        return feedMessage;
      }
      else {
        throw Exception("( gtfs_api_service.dart -> getTramVehiclePositions ) -- Failed to load vehicle positions: ${response.statusCode}");
      }
    } catch(e) {
      throw Exception("( gtfs_api_service.dart -> getTramVehiclePositions ) -- Error fetching vehicle positions $e");
    }
  }
}
