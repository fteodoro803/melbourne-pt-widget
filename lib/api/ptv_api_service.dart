import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Handles fetching Data from the PTV API v3
class PtvApiService {
  final String userId = dotenv.env["PTV_USER_ID"] ?? "emptyPtvUserId";
  final String apiKey = dotenv.env["PTV_API_KEY"] ?? "emptyPtvApiKey";

  // Generate URL for API Calls
  Uri getURL(String request, {Map<String, Object>? parameters}) {
    // Signature
    parameters ??= {}; // initialises if parameters is null
    if (parameters.isEmpty) {
      parameters = {};
    } // initialises if parameters is empty
    parameters['devid'] = userId;

    // Encode the api_key and message to bytes
    final List<int> keyBytes = utf8.encode(apiKey);
    final String signatureValueParameters =
        Uri(queryParameters: parameters).query;
    final String signatureValue = "$request?$signatureValueParameters";
    final List<int> messageBytes = utf8.encode(signatureValue);

    // Generate HMAC SHA1 signature and adding it to Parameters
    final Hmac hmacSha1 = Hmac(sha1, keyBytes);
    final Digest signatureDigest = hmacSha1.convert(messageBytes);
    final String signature = signatureDigest.toString().toUpperCase();
    parameters['signature'] = signature;

    Uri url = Uri(
        scheme: 'https',
        host: 'timetableapi.ptv.vic.gov.au',
        path: request,
        queryParameters: parameters);
    print("(ptv_api_service.dart -> getURL) -- URL: $url");
    return url;
  }

  // Get JSON Response
  Future<Map<String, dynamic>?> getResponse(Uri url) async {
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // print("(ptv_api_service -> getResponse) -- JSON Response: ${response.body}");
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        print(
            "Response Error (ptv_api_service): ${response.statusCode}: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("(ptv_api_service -> getResponse): Fetching error occurred: $e");
      return null;
    }
  }

  // Get Route Types
  Future<Map<String, dynamic>?> routeTypes() async {
    String request = "/v3/route_types";
    Uri url = getURL(request);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> routeTypes): response: $response");  // *test
    return response;
  }

  // Get Routes
  Future<Map<String, dynamic>?> routes({String? routeTypes}) async {
    String request = "/v3/routes";

    // Parameter handling
    Map<String, Object> parameters = {};
    parameters = handleParameters(routeTypes: routeTypes);

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> routes): response: $response");  // *test
    return response;
  }

  // Get Route Directions
  Future<Map<String, dynamic>?> directions(String routeId) async {
    String request = "/v3/directions/route/$routeId";
    Uri url = getURL(request);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> routeDirections): response: $response"); //*test
    return response;
  }

  // Get Stops around a Location
  Future<Map<String, dynamic>?> stopsLocation(String location,
      {String? routeTypes, String? maxResults, String? maxDistance}) async {
    String request = "/v3/stops/location/$location";

    // Parameter handling
    Map<String, Object> parameters = {};
    parameters = handleParameters(
        routeTypes: routeTypes,
        maxResults: maxResults,
        maxDistance: maxDistance);

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> stops) -- response: $response"); //*test
    return response;
  }

  /// Get Stops along a Route
  Future<Map<String, dynamic>?> stopsRoute(String routeId, String routeType,
      {String? directionId, bool? geoPath}) async {
    String request = "/v3/stops/route/$routeId/route_type/$routeType";

    // Parameter handling
    Map<String, Object> parameters = {};
    parameters = handleParameters(directionId: directionId, geoPath: geoPath);

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> stopsAlongRoute) -- stops along route: \n$response");
    return response;
  }

  // Get Departures from a Stop
  Future<Map<String, dynamic>?> departures(String routeType, String stopId,
      {String? routeId,
      String? directionId,
      String? maxResults,
      bool? gtfs,
      String? expand}) async {
    String request;
    if (routeId == null || routeId.isEmpty) {
      request = "/v3/departures/route_type/$routeType/stop/$stopId";
    } else {
      request =
          "/v3/departures/route_type/$routeType/stop/$stopId/route/$routeId";
    }

    // Parameter Handling
    Map<String, Object> parameters = {};
    parameters = handleParameters(
        directionId: directionId,
        maxResults: maxResults,
        gtfs: gtfs,
        expand: expand);

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> departures): response: $response"); //*test
    return response;
  }

  // Runs
  Future<Map<String, dynamic>?> runs(String runRef, String routeType,
      {String? expand}) async {
    String request = "/v3/runs/$runRef/route_type/$routeType";

    // Parameter Handling
    Map<String, Object> parameters = {};
    parameters = handleParameters(expand: expand);

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> runs): response: $response"); //*test
    return response;
  }

  // Patterns
  Future<Map<String, dynamic>?> patterns(String runRef, String routeType,
      {String? expand}) async {
    String request = "/v3/pattern/run/$runRef/route_type/$routeType";

    // Parameter Handling
    Map<String, Object> parameters = {};
    parameters = handleParameters(expand: expand);

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> patterns): response: $response"); //*test
    return response;
  }

  // Disruptions
  Future<Map<String, dynamic>?> disruptions(String routeId) async {
    String request = "/v3/disruptions/route/$routeId";
    Uri url = getURL(request);
    Map<String, dynamic>? response = await getResponse(url);
    return response;
  }

  /// Handles parameters
  // todo: test if this messes with getURLs signature
  Map<String, Object> handleParameters(
      {String? routeTypes,
      String? maxResults,
      String? maxDistance,
      String? directionId,
      bool? geoPath,
      bool? gtfs,
      String? expand}) {
    Map<String, Object> parameters = {};

    // Assumes routeTypes is of the form: "1,2,3,.."
    if (routeTypes != null && routeTypes.isNotEmpty) {
      List<String> types = routeTypes.split(',');
      parameters['route_types'] = types;
    }

    if (maxResults != null && maxResults.isNotEmpty) {
      parameters['max_results'] = maxResults;
    }

    if (maxDistance != null && maxDistance.isNotEmpty) {
      parameters['max_distance'] = maxDistance;
    }

    if (directionId != null && directionId.isNotEmpty) {
      parameters['direction_id'] = directionId;
    }

    if (geoPath != null && geoPath == true) {
      parameters['include_geopath'] = "true";
    }

    if (gtfs != null && gtfs == true) {
      parameters['gtfs'] = "true";
    }

    // Assumes expands is of the form "All" or "Stops,Routes,...", Comma Separated String
    if (expand != null && expand.isNotEmpty) {
      List<String> expands = expand.split(',');
      parameters['expand'] = expands;
    }

    return parameters;
  }
}
