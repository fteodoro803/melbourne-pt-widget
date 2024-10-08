import 'package:flutter_project/ptvInfoClasses/RouteDirectionInfo.dart';

class Route {
  String id;
  String name;
  String number;

  RouteDirection? direction;

  Route({required this.id, required this.name, required this.number});

  @override
  String toString() {
    String str = "Route:\n"
        "\tID: $id\n"
        "\tName: $name \n"
        "\tNumber: $number\n";

    if (direction != null) {
      str += direction.toString();
    }

    return str;
  }
}