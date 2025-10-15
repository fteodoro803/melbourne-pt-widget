class Disruption {
  final int id;
  final String title;
  final String url;
  final String description;
  final String status;
  final String type;
  final DateTime lastUpdated;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<int> routes; // todo: change this to List<Route>

  Disruption(
      {required this.id,
      required this.title,
      required this.url,
      required this.description,
      required this.status,
      required this.type,
      required this.fromDate,
      required this.toDate,
      required this.routes,
      required this.lastUpdated});

  /// Factory constructor to create a Disruption from the PTV API response
  factory Disruption.fromApi({required Map<String, dynamic> data}) {
    // Getting the Routes affected by the disruption
    List<int> routeList = [];
    for (var route in data["routes"]) {
      routeList.add(route["route_id"]);
    }

    return Disruption(
      id: data["disruption_id"],
      title: data["title"],
      url: data["url"],
      description: data["description"],
      status: data["disruption_status"],
      type: data["disruption_type"],
      fromDate:
          data["from_date"] != null ? DateTime.parse(data["from_date"]) : null,
      toDate: data["to_date"] != null ? DateTime.parse(data["to_date"]) : null,
      routes: routeList,
      lastUpdated: DateTime.parse(data["last_updated"]),
    );
  }

  // todo:  Factory constructor to create a Disruption from the Departures PTV API response

  @override
  String toString() {
    return "Disruptions:\n"
        "\tID: $id\t"
        "\tTitle: $title\t"
        "\tURL: $url\n"
        "\tDescription: $description\n"
        "\tStatus: $status\t"
        "\tType: $type\n"
        "\tFrom: $fromDate\t"
        "\tTo: $toDate\t"
        "\tLast Updated: $lastUpdated\n"
        "\tAffected Routes (id): $routes\n";
  }
}
