// idk if the app needs to store this? maybe at most get the users current location to get nearest stops, but delete after~

import 'package:json_annotation/json_annotation.dart';

part 'location_info.g.dart';

@JsonSerializable()
class Location {
  String location;
  // latitude and longitude?

  Location({required this.location});

  @override
  String toString() {
    return "Location: $location\n";
  }

  // Methods for JSON Serialization
  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}