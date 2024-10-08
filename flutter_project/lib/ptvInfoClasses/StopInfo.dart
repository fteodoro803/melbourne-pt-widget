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
}