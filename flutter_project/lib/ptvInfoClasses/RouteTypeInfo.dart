class RouteType {
  String name;      // consider changing the ? to late
  String type;   // 0 - train, 1 - tram, etc

  RouteType({required this.name, required this.type});

  @override
  String toString() {
    return "RouteType:\n"
        "\tType: $type\n"
        "\tName: $name\n";
  }
}