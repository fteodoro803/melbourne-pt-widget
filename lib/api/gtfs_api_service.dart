import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';

class GtfsApiService {
  final String
      subscriptionKey; // todo: store as an environment variable or something
  final String serviceAlertsUrl = "https://data-exchange-api.vicroads.vic.gov.au/opendata/gtfsr/v1/tram/servicealert";
  final String tripUpdatesUrl = "https://data-exchange-api.vicroads.vic.gov.au/opendata/gtfsr/v1/tram/tripupdates";
  final String vehiclePositionsUrl = "https://data-exchange-api.vicroads.vic.gov.au/opendata/gtfsr/v1/tram/vehicleposition";

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
  Future<FeedMessage> getTramTripUpdates() async {
    try {
      final response = await http.get(
        Uri.parse(tripUpdatesUrl),
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

  /// Get Updates for a specific tram route via GTFS
  // todo: move this to ptv_service
  Future<List<TripUpdate>> getTripUpdatesRoute(String routeId) async {
    final feedMessage = await getTramTripUpdates();

    int maxCount = 2;
    int count = 0;

    for (var entity in feedMessage.entity) {
      if (count>=2) {
        break;
      }

      if (entity.hasTripUpdate()) {
        var newEntity = entity.tripUpdate;
        print(entity);
      }
      count++;
    }

    return feedMessage.entity
        .where((entity) => entity.hasTripUpdate())          // filters entities to trips with tripUpdates
        .map((entity) => entity.tripUpdate)                 // turns all those entities to tripUpdates
        .where((update) => update.trip.routeId == routeId)  // filters all tripUpdates to those with same routeId
        .toList();                                          // turns it into a list
  }
}
