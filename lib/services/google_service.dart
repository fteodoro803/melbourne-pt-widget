import 'package:flutter_project/api/google_api_service.dart';

class GoogleService {
  GoogleApiService googleApi = GoogleApiService();

  Future<List<String>> fetchSuggestions(String input) async {
    List<String> suggestions = [];

    var data = await googleApi.getPlaceAutocomplete(input);

    // Empty JSON Response
    if (data == null) {
      print("(google_service.dart -> fetchSuggestions) -- Null data response");
      return suggestions;
    }

    // Adds suggestions to list
    for (var suggestion in data["suggestions"]) {
      String place = suggestion["placePrediction"]["text"]["text"];

      // Contains suggestions to Victoria
      if (place.contains("VIC")) {
        suggestions.add(place);
      }
    }

    return suggestions;
  }
}
