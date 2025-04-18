import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import '../utility/time_utils.dart';
import '../../ptv_info_classes/departure_info.dart';

// Widget for the Address input section with transport type toggle
class DepartureCard extends StatefulWidget {
  final Transport transport;
  final Departure departure;
  final Function(Departure)? onDepartureTapped;

  const DepartureCard({
    super.key,
    required this.transport,
    required this.departure,
    this.onDepartureTapped,
  });

  @override
  _DepartureCardState createState() => _DepartureCardState();
}

class _DepartureCardState extends State<DepartureCard> {

  @override
  Widget build(BuildContext context) {
    final departure = widget.departure;
    final String estimatedDepartureTime = departure.estimatedDepartureTime ?? departure.scheduledDepartureTime ?? "No Data";
    final String scheduledDepartureTime = departure.scheduledDepartureTime ?? "No Data";
    final DepartureStatus status = TransportUtils.getDepartureStatus(
      departure.scheduledDepartureTime,
      departure.estimatedDepartureTime,
    );
    final bool hasLowFloor = departure.hasLowFloor ?? false;
    Map<String,int>? timeDifference = TimeUtils.timeDifference(estimatedDepartureTime);
    String? minutesUntilNextDepartureString = TimeUtils.minutesToString(timeDifference);
    final bool alreadyDeparted = timeDifference!['days']! < 0 || timeDifference['hours']! < 0 || timeDifference['minutes']! < 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      elevation: 1,
      child: ListTile(
        title: Text("${widget.transport.direction?.name}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (departure.platformNumber != null)
              Text(
                "Platform ${departure.platformNumber}",
                style: TextStyle(
                  fontWeight: FontWeight.w500
                ),
              ),
            Row(
              children: [
                Text(
                  status.status,
                  style: TextStyle(
                    color: ColourUtils.getColorForStatus(status.status),
                  ),
                ),
                if (status.timeDifference != null)
                  Text(
                    " ${status.timeDifference} min",
                    style: TextStyle(
                      color: ColourUtils.getColorForStatus(status.status),
                    ),
                  ),
                Text(
                  " • ",
                  style: TextStyle(
                    color: ColourUtils.getColorForStatus(status.status),
                  ),
                ),
                if (minutesUntilNextDepartureString != null)...[
                  Text(
                    TimeUtils.trimTime(scheduledDepartureTime),
                    style: TextStyle(
                      color: ColourUtils.getColorForStatus(status.status),
                      decoration: status.timeDifference != null ? TextDecoration.lineThrough : null,
                      decorationColor: ColourUtils.getColorForStatus(status.status),
                    ),
                  ),
                  Text(
                    " • ",
                    style: TextStyle(
                      color: ColourUtils.getColorForStatus(status.status),
                    ),
                  ),
                ],

                if (hasLowFloor) ...[
                  Icon(Icons.accessible, size: 18),
                  SizedBox(width: 2)

                  // SizedBox(width: 4),
                  // Image.asset(
                  //   "assets/icons/Low Floor Icon.png",
                  //   width: 14,
                  //   height: 14,
                  // ),
                ],
                // Icon(Icons.people_outline, size: 20),
                Icon(Icons.people_outline_outlined, size: 20),
                // Icon(Icons.people_sharp, size: 20)
              ],
            ),
          ],
        ),
        trailing: minutesUntilNextDepartureString != null
          ? Text(
            minutesUntilNextDepartureString,
            style: TextStyle(
              fontSize: 15,
              color: ColourUtils.getColorForStatus(status.status),
            ),
          )
          : Text(
            TimeUtils.trimTime(scheduledDepartureTime),
            style: TextStyle(
              fontSize: 15,
              color: ColourUtils.getColorForStatus(status.status),
            ),
          ),
        onTap: () {
          if (widget.onDepartureTapped != null) {
            setState(() {
              widget.onDepartureTapped!(departure);
            });
          }
        },
      ),

    );
  }
}