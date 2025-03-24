import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';
import '../file_service.dart';
import '../time_utils.dart';
import '../widgets/departures_list.dart';

class StopDetailsSheet extends StatefulWidget {

  final ScreenArguments arguments;
  const StopDetailsSheet({super.key, required this.arguments});

  @override
  State<StopDetailsSheet> createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<StopDetailsSheet> {

  @override
  Widget build(BuildContext context) {
    print("(stop_details_sheet.dart) -- Departures: ${widget.arguments.searchDetails.directions[0].departures}");
    final transport1 = widget.arguments.searchDetails.directions[0];
    final transport2 = widget.arguments.searchDetails.directions[1];

    final transport1Departure1 = transport1.departures?[0];
    final transport1Departure2 = transport1.departures?[1];
    final transport2Departure1 = transport2.departures?[0];
    final transport2Departure2 = transport2.departures?[1];

    final String transport1Departure1Time = transport1Departure1?.estimatedDepartureTime ?? transport1Departure1?.scheduledDepartureTime ?? "No Data";
    final String transport1Departure2Time = transport1Departure2?.estimatedDepartureTime ?? transport1Departure2?.scheduledDepartureTime ?? "No Data";
    final String transport2Departure1Time = transport2Departure1?.estimatedDepartureTime ?? transport2Departure1?.scheduledDepartureTime ?? "No Data";
    final String transport2Departure2Time = transport2Departure2?.estimatedDepartureTime ?? transport2Departure2?.scheduledDepartureTime ?? "No Data";

    final DepartureStatus transport1Departure1TimeStatus = TransportUtils.getDepartureStatus(
      transport1Departure1?.estimatedDepartureTime,
      transport1Departure1?.scheduledDepartureTime,
    );
    final DepartureStatus transport1Departure2TimeStatus = TransportUtils.getDepartureStatus(
      transport1Departure2?.estimatedDepartureTime,
      transport1Departure2?.scheduledDepartureTime,
    );
    final DepartureStatus transport2Departure1TimeStatus = TransportUtils.getDepartureStatus(
      transport2Departure1?.estimatedDepartureTime,
      transport2Departure1?.scheduledDepartureTime,
    );
    final DepartureStatus transport2Departure2TimeStatus = TransportUtils.getDepartureStatus(
      transport2Departure2?.estimatedDepartureTime,
      transport2Departure2?.scheduledDepartureTime,
    );

    final bool transport1Departure1HasLowFloor = transport1Departure1?.hasLowFloor ?? false;
    final bool transport1Departure2HasLowFloor = transport1Departure2?.hasLowFloor ?? false;
    final bool transport2Departure1HasLowFloor = transport2Departure1?.hasLowFloor ?? false;
    final bool transport2Departure2HasLowFloor = transport2Departure2?.hasLowFloor ?? false;

    String transport1Departure1MinutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(transport1Departure1Time));
    String transport1Departure2MinutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(transport1Departure2Time));
    String transport2Departure1MinutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(transport2Departure1Time));
    String transport2Departure2MinutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(transport2Departure2Time));

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  red: 0,
                  green: 0,
                  blue: 0,
                  alpha: 0.1,
                ),
                spreadRadius: 1,
                blurRadius: 7,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Draggable Scrollable Sheet Handle
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Stop and route details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Stop location
                      Row(
                        children: [
                          Icon(Icons.location_pin, size: 16),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              widget.arguments.searchDetails.stop!.name,
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),

                      // Route details
                      Row(
                        children: [
                          Image.asset(
                            "assets/icons/PTV Tram Logo.png",
                            width: 40,
                            height: 40,
                          ),
                          SizedBox(width: 8),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.arguments.searchDetails.route!.number,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      Text(
                          "Towards ${transport1.direction?.name}",
                          style: TextStyle(
                            fontSize: 16,
                          )
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        elevation: 1,
                        child: ListTile(
                          title: Text("${widget.arguments.searchDetails.directions[0].direction?.name}"),
                          subtitle: Row(
                            children: [
                              Text(
                                "${transport1Departure1TimeStatus.status} ",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport1Departure1TimeStatus.status),
                                ),
                              ),
                              Text(
                                transport1Departure1TimeStatus.timeDifference != null ? "${transport1Departure1TimeStatus.timeDifference} min • $transport1Departure1Time" : "• $transport1Departure1Time",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport1Departure1TimeStatus.status),
                                ),
                              ),
                              if (transport1Departure1HasLowFloor) ...[
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
                            transport1Departure1MinutesUntilNextDepartureString,
                            style: TextStyle(
                              fontSize: 15,
                              color: TransportUtils.getColorForStatus(transport1Departure1TimeStatus.status),
                            ),
                          ),
                          onTap: () {},
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        elevation: 1,
                        child: ListTile(
                          title: Text("${widget.arguments.searchDetails.directions[0].direction?.name}"),
                          subtitle: Row(
                            children: [
                              Text(
                                "${transport1Departure2TimeStatus.status} ",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport1Departure2TimeStatus.status),
                                ),
                              ),
                              Text(
                                transport1Departure2TimeStatus.timeDifference != null ? "${transport1Departure2TimeStatus.timeDifference} min • $transport1Departure2Time" : "• $transport1Departure2Time",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport1Departure2TimeStatus.status),
                                ),
                              ),
                              if (transport1Departure2HasLowFloor) ...[
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
                            transport1Departure2MinutesUntilNextDepartureString,
                            style: TextStyle(
                              fontSize: 15,
                              color: TransportUtils.getColorForStatus(transport1Departure2TimeStatus.status),
                            ),
                          ),
                          onTap: () {},
                        ),
                      ),
                      SizedBox(height: 12),

                      // DeparturesList(departuresLength: 2, transport: widget.arguments.searchDetails.directions[0]),
                      Text(
                          "Towards ${transport2.direction?.name}",
                          style: TextStyle(
                            fontSize: 16,
                          )),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        elevation: 1,
                        child: ListTile(
                          title: Text("${widget.arguments.searchDetails.directions[1].direction?.name}"),
                          subtitle: Row(
                            children: [
                              Text(
                                "${transport2Departure1TimeStatus.status} ",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport2Departure1TimeStatus.status),
                                ),
                              ),
                              Text(
                                transport2Departure1TimeStatus.timeDifference != null ? "${transport2Departure1TimeStatus.timeDifference} min • $transport2Departure1Time" : "• $transport2Departure1Time",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport2Departure1TimeStatus.status),
                                ),
                              ),
                              if (transport2Departure1HasLowFloor) ...[
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
                            transport2Departure1MinutesUntilNextDepartureString,
                            style: TextStyle(
                              fontSize: 15,
                              color: TransportUtils.getColorForStatus(transport2Departure1TimeStatus.status),
                            ),
                          ),
                          onTap: () {},
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        elevation: 1,
                        child: ListTile(
                          title: Text("${widget.arguments.searchDetails.directions[0].direction?.name}"),
                          subtitle: Row(
                            children: [
                              Text(
                                "${transport2Departure2TimeStatus.status} ",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport2Departure2TimeStatus.status),
                                ),
                              ),
                              Text(
                                transport2Departure2TimeStatus.timeDifference != null ? "${transport2Departure2TimeStatus.timeDifference} min • $transport2Departure2Time" : "• $transport2Departure2Time",
                                style: TextStyle(
                                  color: TransportUtils.getColorForStatus(transport2Departure2TimeStatus.status),
                                ),
                              ),
                              if (transport2Departure2HasLowFloor) ...[
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
                            transport2Departure2MinutesUntilNextDepartureString,
                            style: TextStyle(
                              fontSize: 15,
                              color: TransportUtils.getColorForStatus(transport2Departure2TimeStatus.status),
                            ),
                          ),
                          onTap: () {},
                        ),
                      ),
                      // DeparturesList(departuresLength: 2, transport: widget.arguments.searchDetails.directions[0]),
                      // ListTile(
                      //   title: Column(
                      //     children: [
                      //
                      //     ],
                      //   ),
                      //   onTap: () async {
                      //     // await append(widget.arguments.searchDetails.directions[0]);
                      //     // widget.arguments.callback(); // calls the screen arguments callback function
                      //     // Navigator.popUntil(context, ModalRoute.withName("/"));
                      //   }
                      // ),
                      //
                      // ListTile(
                      //   title: Column(
                      //     children: [
                      //
                      //     ],
                      //   ),
                      //   onTap: () async {
                      //     // await append(widget.arguments.searchDetails.directions[1]);
                      //     // widget.arguments.callback(); // calls the screen arguments callback function
                      //     // Navigator.popUntil(context, ModalRoute.withName("/"));
                      //   }
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

  }
}