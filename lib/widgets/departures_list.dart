import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import '../../time_utils.dart';
import '../ptv_info_classes/departure_info.dart';

// Widget for the Address input section with transport type toggle
class DeparturesList extends StatefulWidget {
  final int departuresLength;
  final Transport transport;
  final bool lowFloorFilter;
  final bool airConditionerFilter;
  final Function(Departure)? onDepartureTapped;

  const DeparturesList({
    super.key,
    required this.departuresLength,
    required this.transport,
    required this.lowFloorFilter,
    required this.airConditionerFilter,
    this.onDepartureTapped,
  });

  @override
  _DeparturesListState createState() => _DeparturesListState();
}

class _DeparturesListState extends State<DeparturesList> {

  @override
  Widget build(BuildContext context) {

    List<Departure>? filteredDepartures = widget.transport.departures;
    if (widget.lowFloorFilter) {
      filteredDepartures = widget.transport.departures?.where((departure) => departure.hasLowFloor == widget.lowFloorFilter).toList();
    }

    return ListView.builder(
        shrinkWrap: true,
        controller: ScrollController(),
        padding: const EdgeInsets.only(
          top: 0.0,
          // right: 8.0,
          bottom: 0.0,
          // left: 8.0,
        ),
        itemCount: filteredDepartures!.length > widget.departuresLength ? widget.departuresLength : filteredDepartures.length,
        itemBuilder: (context, index) {
          final departure = filteredDepartures?[index];
          final String departureTime = departure?.estimatedDepartureTime ?? departure?.scheduledDepartureTime ?? "No Data";
          final DepartureStatus status = TransportUtils.getDepartureStatus(
            departure?.estimatedDepartureTime,
            departure?.scheduledDepartureTime,
          );
          final bool hasLowFloor = departure?.hasLowFloor ?? false;
          String? minutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(departureTime));

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2.0),
            elevation: 1,
            child: ListTile(
              title: Text("${widget.transport.direction?.name}"),
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
              trailing: minutesUntilNextDepartureString != null
                ? Text(
                  minutesUntilNextDepartureString,
                  style: TextStyle(
                    fontSize: 15,
                    color: TransportUtils.getColorForStatus(status.status),
                  ),
                )
                : null,
              onTap: () {
                if (widget.onDepartureTapped != null) {
                  setState(() {
                    widget.onDepartureTapped!(departure!);
                  });
                }
              },
            ),
          );
        },
      );
  }
}