import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../ptv_info_classes/departure_info.dart';
import '../ptv_service.dart';
import '../screen_arguments.dart';
import '../time_utils.dart';
import '../transport.dart';
import '../widgets/transport_widgets.dart';

class DepartureDetailsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Departure departure;

  DepartureDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.departure,
  });

  @override
  _DepartureDetailsSheetState createState() => _DepartureDetailsSheetState();
}

class _DepartureDetailsSheetState extends State<DepartureDetailsSheet> {
  late Transport transport;
  PtvService ptvService = PtvService();
  late List<Departure> _pattern = [];
  late int _currentStopIndex;

  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    transport = widget.arguments.transport;
    fetchPattern();
    // itemScrollController.jumpTo(index: _currentStopIndex!);
  }

  Future<void> fetchPattern() async {
    _pattern = await ptvService.fetchPattern(transport, widget.departure);

    // Find the current stop index
    _currentStopIndex = _pattern.indexWhere(
        (stop) => stop.stopName?.trim().toLowerCase() == transport.stop?.name.trim().toLowerCase()
    );

    // If the stop isn't found, default to 0
    if (_currentStopIndex == -1) {
      _currentStopIndex = 0;
    }

    setState(() {});

    // Scroll to the item after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
            index: _currentStopIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0
        );
      }
    });

    // print("Pattern: ${_pattern}");
    // for (var stop in _pattern!) { print("Stop name: ${stop.stopName}");}
    // print("Current stop name: ${transport.stop?.name}");
    //
    // print(_currentStopIndex);
    //
    // print(transport.direction);
    // print(transport.route!.name);
    // print(_pattern[0].stopName);
    for (var stop in _pattern!) {
      print("Stop name: ${stop.stopName}");
      print("Scheduled departure time: ${stop.scheduledDepartureTime}");
      print("Estimated departure time: ${stop.estimatedDepartureTime}");
    }

  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // DraggableScrollableSheet Handle
        HandleWidget(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            controller: widget.scrollController,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Route and stop details
                        Flexible(
                          fit: FlexFit.tight,
                          child: Column(
                            children: [
                              LocationWidget(textField: transport.stop!.name, textSize: 16, scrollable: true),
                              SizedBox(height: 4),
                              RouteWidget(route: transport.route!, direction: transport.direction, scrollable: true),
                              SizedBox(height: 4),
                              Text("Scheduled: ${widget.departure.scheduledDepartureTime}"),
                              SizedBox(height: 4),
                              Text("Estimated: ${widget.departure.estimatedDepartureTime ?? 'N/A'}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Divider(),
                  ],
                ),
              ),

              Container(
                height: MediaQuery.of(context).size.height * 0.6, // Use a fixed or calculated height
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: NotificationListener<ScrollNotification>(
                  // This prevents the scroll events from bubbling up to the DraggableScrollableSheet
                  onNotification: (ScrollNotification notification) {
                    // Return true to stop the notification from bubbling up
                    return true;
                  },
                  child: ScrollablePositionedList.builder(
                    itemScrollController: itemScrollController,
                    itemPositionsListener: ItemPositionsListener.create(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      top: 0.0,
                      bottom: 0.0,
                    ),
                    itemCount: _pattern.length,
                    itemBuilder: (context, index) {
                      final stopDeparture = _pattern[index];
                      final stopName = stopDeparture.stopName;
                      final departureTime = stopDeparture.scheduledDepartureTime!;

                      final timeDifference = TimeUtils.timeDifference(departureTime);
                      // print(timeDifference);
                      String? minutesUntilNextDepartureString = TimeUtils.minutesToString(TimeUtils.timeDifference(departureTime!));

                      return Card(
                        color: index == _currentStopIndex ? Theme.of(context).colorScheme.surfaceContainerHigh : null,
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        elevation: 1,
                        child: ListTile(
                          leading: SizedBox(
                            width: 55,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(TransportUtils.trimTime(departureTime), style: TextStyle(fontSize: 12),),
                                if (minutesUntilNextDepartureString != null )
                                  Container(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF93BA96),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        minutesUntilNextDepartureString,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                        ),
                                      )
                                  ),
                              ],
                            ),
                          ),
                          title: Row(
                            children: [
                              Container(
                                width: 5, // Width of the vertical line
                                color: timeDifference!['minutes']! >= 0 && timeDifference['hours']! >= 0 ? Colors.green : Colors.grey, // Color of the vertical line
                                height: 60, // Adjust the height of the vertical line
                              ),
                              SizedBox(width: 12),
                              Expanded(child: Text(stopName!, overflow: TextOverflow.ellipsis, maxLines: 2,)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }
}
