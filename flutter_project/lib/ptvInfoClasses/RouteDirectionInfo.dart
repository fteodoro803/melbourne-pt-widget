class RouteDirection {
  String id;
  String name;
  String description;

  RouteDirection({required this.id, required this.name, required this.description});

  @override
  String toString() {
    return "Route Direction:\n"
        "\tID: $id\n"
        "\tName: $name\n";
  }
}