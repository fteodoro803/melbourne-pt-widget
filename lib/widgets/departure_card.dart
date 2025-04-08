import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import '../utility/time_utils.dart';
import '../ptv_info_classes/departure_info.dart';

// Widget for the Address input section with transport type toggle
class DepartureCard extends StatefulWidget {
  final Transport transport;
  final Departure departure;
  final Function(Departure, Transport)? onDepartureTapped;

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
    String? minutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(estimatedDepartureTime));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      elevation: 1,
      child: ListTile(
        title: Text("${widget.transport.direction?.name}"),
        subtitle: Row(
          children: [
            Text(
              "${status.status}",
              style: TextStyle(
                color: TransportUtils.getColorForStatus(status.status),
              ),
            ),
            if (status.timeDifference != null)
              Text(
                " ${status.timeDifference} min",
                style: TextStyle(
                  color: TransportUtils.getColorForStatus(status.status),
                ),
              ),
            Text(
              " • ",
              style: TextStyle(
                color: TransportUtils.getColorForStatus(status.status),
              ),
            ),
            if (minutesUntilNextDepartureString != null)...[
              Text(
                TransportUtils.trimTime(scheduledDepartureTime),
                style: TextStyle(
                  color: TransportUtils.getColorForStatus(status.status),
                  decoration: status.timeDifference != null ? TextDecoration.lineThrough : null,
                  decorationColor: TransportUtils.getColorForStatus(status.status),
                ),
              ),
              Text(
                " • ",
                style: TextStyle(
                  color: TransportUtils.getColorForStatus(status.status),
                ),
              ),
            ],

            if (hasLowFloor) ...[

              // SizedBox(width: 4),
              Image.asset(
                "assets/icons/Low Floor Icon.png",
                width: 14,
                height: 14,
              ),
            ],
          ],
        ),
        trailing: minutesUntilNextDepartureString != null
            ? Text(
          minutesUntilNextDepartureString,
          style: TextStyle(
            fontSize: 15,
            color: TransportUtils.getColorForStatus(status.status),
          ),
        )
            : Text(
          TransportUtils.trimTime(scheduledDepartureTime),
          style: TextStyle(
            fontSize: 15,
            color: TransportUtils.getColorForStatus(status.status),
          ),
        ),
        onTap: () {
          if (widget.onDepartureTapped != null) {
            setState(() {
              widget.onDepartureTapped!(departure, widget.transport);
            });
          }
        },
      ),

    );
  }
}