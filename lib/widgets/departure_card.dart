import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import '../../time_utils.dart';
import '../ptv_info_classes/departure_info.dart';

// Widget for the Address input section with transport type toggle
class DepartureCard extends StatelessWidget {
  final Departure departure;
  final Transport transport;

  const DepartureCard({
    super.key,
    required this.departure,
    required this.transport,
  });

  @override
  Widget build(BuildContext context) {
    final String departureTime = departure.estimatedDepartureTime ?? departure.scheduledDepartureTime ?? "No Data";
    final DepartureStatus status = TransportUtils.getDepartureStatus(
      departure.estimatedDepartureTime,
      departure.scheduledDepartureTime,
    );
    final bool hasLowFloor = departure.hasLowFloor ?? false;
    String minutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(departureTime));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      elevation: 1,
      child: ListTile(
        title: Text("${transport.direction?.name}"),
        subtitle: Row(
          children: [
            Text(
              "${status.status} ",
              style: TextStyle(
                color: TransportUtils.getColorForStatus(status.status),
              ),
            ),
            Text(
              status.timeDifference != null ? "${status.timeDifference} min • $departureTime" : "• $departureTime",
              style: TextStyle(
                color: TransportUtils.getColorForStatus(status.status),
              ),
            ),
            if (hasLowFloor) ...[
              SizedBox(width: 4),
              Image.asset(
                "assets/icons/Low Floor Icon.png",
                width: 14,
                height: 14,
              ),
            ],
          ],
        ),
        trailing:
        Text(
          minutesUntilNextDepartureString,
          style: TextStyle(
            fontSize: 15,
            color: TransportUtils.getColorForStatus(status.status),
          ),
        ),
        // onTap: () {},
      ),
    );
  }
}