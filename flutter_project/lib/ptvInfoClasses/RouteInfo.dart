class Route {
  String id;
  String name;
  String number;
  String? direction;

  Route({required this.id, required this.name, required this.number});

  @override
  String toString() {
    String str = "Route:"
        "\n\tID: $id"
        "\n\tName (Number): $name($number)";

    if (direction != null) {
      str += "\n\tDirection: $direction";
    }

    return str;
  }
}