import 'package:flutter/material.dart';
import 'package:flutter_project/domain/trip.dart';
import '../utility/time_utils.dart';
import '../utility/trip_utils.dart';
import '../../domain/departure.dart';

// Widget for the Address input section with trip type toggle
class DepartureCard extends StatefulWidget {
  final Trip trip;
  final Departure departure;
  final Function(Departure)? onDepartureTapped;

  const DepartureCard({
    super.key,
    required this.trip,
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
    final DateTime scheduled = departure.scheduledDepartureUTC!;
    final DateTime? estimated = departure.estimatedDepartureUTC;

    final status = TimeUtils.getDepartureStatus(scheduled, estimated);
    final bool hasLowFloor = departure.hasLowFloor ?? false;
    final String minutesString = TimeUtils.minutesString(estimated, scheduled);
    final String statusString = TimeUtils.statusString(status);
    final String timeStringScheduled = TimeUtils.trimTime(scheduled, false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      elevation: 1,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 16, right: 16),
        title: Text(
          "${widget.trip.direction?.name}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                // Status string, e.g. "Departed late" or "4 min early"
                Text(
                  statusString,
                  style: TextStyle(
                    color: ColourUtils.hexToColour(status.getColorString),
                  ),
                ),

                Text(
                  " • ",
                  style: TextStyle(
                    color: ColourUtils.hexToColour(status.getColorString),
                  ),
                ),

                // Scheduled time string, e.g. "5:45 pm"
                if (TimeUtils.showDepartureTime(scheduled))...[
                  Text(
                    timeStringScheduled,
                    style: TextStyle(
                      color: ColourUtils.hexToColour(status.getColorString),
                      decoration: status.timeDifference != null ? TextDecoration.lineThrough : null,
                      decorationColor: ColourUtils.hexToColour(status.getColorString),
                    ),
                  ),
                  if (status.hasDeparted == false)
                    Text(
                      " • ",
                      style: TextStyle(
                        color: ColourUtils.hexToColour(status.getColorString),
                      ),
                    ),

                ],

                if (status.hasDeparted == false)...[
                  if (hasLowFloor) ...[
                    Icon(Icons.accessible, size: 18),
                    SizedBox(width: 2)
                  ],
                  // Icon(Icons.people_outline, size: 20),
                  Icon(Icons.people_outline_outlined, size: 20),
                  // Icon(Icons.people_sharp, size: 20)
                ]


              ],
            ),
          ],
        ),

        // Minutes string, e.g. "5 min ago", "8:45 pm", "Fri, 5 Apr"
        trailing: Text(
          minutesString,
          style: TextStyle(
            fontSize: 15,
            color: ColourUtils.hexToColour(status.getColorString),
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