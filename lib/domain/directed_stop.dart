import 'package:flutter_project/domain/stop.dart';
import 'package:flutter_project/domain/trip.dart';

class DirectedStop {
  List<Trip> trips;
  Stop stop;
  String direction;

  DirectedStop({required this.trips, required this.stop, required this.direction});

  @override
  String toString() {
    String str = "";
    str += "Directed Stop: Routes [${trips.map((t) => t.route?.id).toList()}] at Stop ${stop.id} towards $direction\n";
    return str;
  }
}