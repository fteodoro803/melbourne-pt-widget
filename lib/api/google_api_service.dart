import 'dart:convert';

import 'package:flutter_project/api_data.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;

class GoogleApiService {
  String apiKey = GlobalConfiguration().get("googleApiKey");

  Future<ApiData> getPlaceAutocomplete(String input) async {
    const String url = "https://places.googleapis.com/v1/places:autocomplete";

    final Map<String, dynamic> requestBody = {
      "input": input,
      "languageCode": "en",
      "regionCode": "US",
      "locationRestriction": {
        "rectangle": { // rectangle surrounding Victoria
          "low": {
            "latitude": -39.26633899352238,
            "longitude": 140.83244781910867
          },
          "high": {
            "latitude": -34.316276697485925,
            "longitude": 150.18181302956168
          }
        }
      }
    };

    Uri uri = Uri.parse(url);
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'suggestions.placePrediction.text.text'
    };

    final response = await http.post(uri, headers: headers, body: jsonEncode(requestBody));
    Map<String, dynamic>? jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      print(
          '(google_api_service.dart -> getPlaceAutoComplete) -- Response: ${response
              .body}');
      return ApiData(uri, jsonResponse);
    } else {
      print(
          '(google_api_service.dart -> getPlaceAutoComplete) -- Error: ${response
              .statusCode} - ${response.body}');
      return ApiData(uri, null);
    }
  }
}