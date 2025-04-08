import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/api/google_api_service.dart';

class GoogleService {
  GoogleApiService googleApi = GoogleApiService();

  Future<List<String>> fetchSuggestions(String input) async {
    List<String> suggestions = [];

    ApiData data = await googleApi.getPlaceAutocomplete(input);
    Map<String, dynamic>? jsonResponse = data.response;

    // Empty JSON Response
    if (jsonResponse == null) {
      print("(google_service.dart -> fetchSuggestions) -- Null data response");
      return suggestions;
    }

    // Adds suggestions to list
    for (var suggestion in jsonResponse["suggestions"]) {
      String place = suggestion["placePrediction"]["text"]["text"];

      // Contains suggestions to Victoria
      if (place.contains("VIC")) {
        suggestions.add(place);
      }
    }

    return suggestions;
  }
}