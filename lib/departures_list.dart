import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import '../time_utils.dart';

// Widget for the Address input section with transport type toggle
class DeparturesList extends StatelessWidget {
  final int departuresLength;
  final Transport transport;

  const DeparturesList({
    super.key,
    required this.departuresLength,
    required this.transport,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: ScrollController(),
        padding: const EdgeInsets.only(
          top: 0.0,
          right: 16.0,
          bottom: 0.0,
          left: 16.0,
        ),
        itemCount: transport.departures!.length > departuresLength ? departuresLength : transport.departures?.length,
        itemBuilder: (context, index) {
          final departure = transport.departures?[index];
          final String departureTime = departure?.estimatedDepartureTime ?? departure?.scheduledDepartureTime ?? "No Data";
          final DepartureStatus status = TransportUtils.getDepartureStatus(
            departure?.estimatedDepartureTime,
            departure?.scheduledDepartureTime,
          );
          final bool hasLowFloor = departure?.hasLowFloor ?? false;
          String minutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(departureTime));

          return ListTile(
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
            onTap: () {
            },
          );
        },
      ),
    );
  }
}