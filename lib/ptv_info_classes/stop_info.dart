import 'package:json_annotation/json_annotation.dart';

part 'stop_info.g.dart';

@JsonSerializable()
class Stop {
  int id;      // convert this to integer ~note
  String name;      //~note what happens if in an api call, these are null?

  // idk if these are necessary
  String? suburb;
  double? latitude;
  double? longitude;
  double? distance;

  Stop({required this.id, required this.name, required this.latitude, required this.longitude, this.distance});

  @override
  String toString() {
    return "Stop:\n"
        "\tID: $id\t"
        "\tName: $name\n"
        "\tLatitude: $latitude\n"
        "\tLongitude: $longitude\n"
        "\tDistance: $distance\n";
  }

  // Methods for JSON Serialization
  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
  Map<String, dynamic> toJson() => _$StopToJson(this);
}