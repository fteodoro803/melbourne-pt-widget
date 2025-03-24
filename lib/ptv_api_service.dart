/*
Handles the data requests to the PTV API
*/

import 'dart:convert';
import 'package:flutter_project/api_data.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;

import 'package:crypto/crypto.dart';

// Handles fetching Data from API
class PtvApiService {
  String userId = GlobalConfiguration().get("ptvUserId");
  String apiKey = GlobalConfiguration().get("ptvApiKey");

  // Generate URL for API Calls
  Uri getURL(String request, {Map<String, String>? parameters}) {
    // Signature
    parameters ??= {};    // initialises if parameters is null
    if (parameters.isEmpty) { parameters = {}; }    // initialises if parameters is empty
    parameters ['devid'] = userId;

    // Encode the api_key and message to bytes
    final List<int> keyBytes = utf8.encode(apiKey);
    final String signatureValueParameters = Uri(queryParameters: parameters).query;
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
    return url;
  }

  // Get JSON Response
  Future<Map<String, dynamic>?> getResponse(Uri url) async {
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        print("Response Error (ptv_api_service): ${response.statusCode}: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("(ptv_api_service -> getResponse): Fetching error occurred: $e");
      return null;
    }
  }

  // Get Route Types
  Future<ApiData> routeTypes() async {
    String request = "/v3/route_types";
    Uri url = getURL(request);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(pt v_api_service -> routeTypes): response: $response");  // *test
    return ApiData(url, response);
  }

  // Get Route Directions
  Future<ApiData> routeDirections(String routeId) async {
    String request = "/v3/directions/route/$routeId";
    Uri url = getURL(request);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> routeDirections): response: $response"); //*test
    return ApiData(url, response);
  }

  // Get Stops around a Location
  Future<ApiData> stops(String location,
      {String? routeTypes, String? maxResults, String? maxDistance}) async {
    String request = "/v3/stops/location/$location";
    Map<String, String> parameters = {};

    // Parameter handling
    if (routeTypes != null && routeTypes.isNotEmpty) {
      List<String> routeTypesList = routeTypes.split(',');
      for (int i=0; i<routeTypesList.length; i++) {
        parameters['route_types'] = routeTypesList[i];
      }
    }
    if (maxResults != null && maxResults.isNotEmpty) {
      parameters['max_results'] = maxResults;
    }
    if (maxDistance != null && maxDistance.isNotEmpty) {
      parameters['max_distance'] = maxDistance;
    }

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    print("(ptv_api_service -> stops): response: $response"); //*test
    return ApiData(url, response);
  }

  // Get Departures from a Stop
  Future<ApiData> departures(String routeType, String stopId, {String? routeId, String? directionId, String? maxResults, String? expand}) async {
    String request;
    if (routeId == null || routeId.isEmpty) {
      request = "/v3/departures/route_type/$routeType/stop/$stopId";
    }
    else {
      request = "/v3/departures/route_type/$routeType/stop/$stopId/route/$routeId";
    }

    // Parameter Handling
    Map<String, String> parameters = {};
    if (directionId != null && directionId.isNotEmpty) {
      parameters['direction_id'] = directionId;
    }
    if (maxResults != null && maxResults.isNotEmpty) {
      parameters['max_results'] = maxResults;
    }
    // print('(ptv_api_service.dart): expand: $expand');
    if (expand != null && expand.isNotEmpty) {
      List<String> expandList = expand.split(',');
      // print('(ptv_api_service.dart): expandList: $expandList');
      for (int i=0; i<expandList.length; i++) {
        parameters['expand'] = expandList[i];   // NOTE :::: SO FAR THIS IS WRONG BC IT OVERWRITES THE PREVIOUS EXPAND, BC THERE ARE NO DUPLICATE KEYS IN MAP
      }
      // print('(ptv_api_service.dart): parameters: $parameters');
    }

    Uri url = getURL(request, parameters: parameters);
    Map<String, dynamic>? response = await getResponse(url);
    // print("(ptv_api_service -> departures): response: $response"); //*test
    return ApiData(url, response);
  }
}
