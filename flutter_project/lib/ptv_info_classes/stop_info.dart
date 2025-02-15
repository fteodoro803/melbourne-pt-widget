import 'package:json_annotation/json_annotation.dart';

part 'stop_info.g.dart';

@JsonSerializable()
class Stop {
  String id;
  String name;

  // idk if these are necessary
  String? suburb;
  String? latitude;
  String? longitude;

  Stop({required this.id, required this.name});

  @override
  String toString() {
    return "Stop:\n"
        "\tID: $id\n"
        "\tName: $name\n";
  }

  // Methods for JSON Serialization
  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
  Map<String, dynamic> toJson() => _$StopToJson(this);
}