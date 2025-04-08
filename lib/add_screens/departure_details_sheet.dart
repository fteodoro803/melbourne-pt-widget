import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../ptv_info_classes/departure_info.dart';
import '../ptv_service.dart';
import '../screen_arguments.dart';
import '../utility/time_utils.dart';
import '../transport.dart';
import '../widgets/screen_widgets.dart';
import '../widgets/transport_widgets.dart';

class DepartureDetailsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;

  DepartureDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
  });

  @override
  _DepartureDetailsSheetState createState() => _DepartureDetailsSheetState();
}

class _DepartureDetailsSheetState extends State<DepartureDetailsSheet> {
  late Transport transport;
  PtvService ptvService = PtvService();
  late List<Departure> _pattern = [];
  late int _currentStopIndex;

  ItemScrollController itemScrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();


  @override
  void initState() {
    super.initState();
    transport = widget.arguments.transport;
    fetchPattern();
  }

  Future<void> fetchPattern() async {
    _pattern = await ptvService.fetchPattern(transport, widget.arguments.searchDetails!.departure!);

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 100));
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
          index: _currentStopIndex,
          duration: Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          alignment: 0,
        );
      }
    });

  }

  @override
  Widget build(BuildContext context) {

    final departure = widget.arguments.searchDetails!.departure!;
    final String estimatedDepartureTime = departure.estimatedDepartureTime ?? departure.scheduledDepartureTime ?? "No Data";
    final DepartureStatus status = TransportUtils.getDepartureStatus(
      departure.scheduledDepartureTime,
      departure.estimatedDepartureTime,
    );
    Map<String, int>? timeToDeparture = TimeUtils.timeDifference(estimatedDepartureTime);


    String timeString = "At ${TransportUtils.trimTime(estimatedDepartureTime)}";
    if (timeToDeparture!['days']! < 0 || timeToDeparture['hours']! < 0) {
      timeString = "Departed ${TransportUtils.trimTime(estimatedDepartureTime)}";
    }
    else if (timeToDeparture['days'] == 0 && timeToDeparture['hours'] == 0) {
      if (timeToDeparture['minutes'] == 0) {
        timeString = "Departing now";
      }
      else if (timeToDeparture['minutes']! < 0) {
        timeString = "${timeToDeparture['minutes']!.abs()} min ago";
      }
      else {
        timeString = "In ${timeToDeparture['minutes']!} min";
      }
    }

    // Add listener to the ItemPositionsListener
    _itemPositionsListener.itemPositions.addListener(() {
      final firstVisibleItem = _itemPositionsListener.itemPositions.value.isNotEmpty
          ? _itemPositionsListener.itemPositions.value.first
          : null;
      print(firstVisibleItem);

      if (firstVisibleItem != null) {
        if (firstVisibleItem.index == 0 && firstVisibleItem.itemLeadingEdge > 0) {
          widget.scrollController.jumpTo(0);
        }
      }
    });

    return Column(
      children: [
        // DraggableScrollableSheet Handle
        if (!widget.arguments.searchDetails!.isSheetExpanded)
          HandleWidget(),

        Expanded(
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
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
                                LocationWidget(textField: transport.stop!.name, textSize: 18, scrollable: true),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: Color(0xFF717171),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(transport.direction!.name, style: TextStyle(fontSize: 16, height: 1.1), overflow: TextOverflow.ellipsis, maxLines: 2),
                                          SizedBox(height: 8),
                                          RouteWidget(route: transport.route!, scrollable: true),
                                          SizedBox(height: 4)
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),

                                    Card(
                                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                      elevation: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 2),
                                            Container(
                                              padding: EdgeInsets.symmetric(vertical: 1, horizontal: 6),
                                              decoration: BoxDecoration(

                                                color: TransportUtils.getColorForStatus(status.status),
                                                borderRadius: BorderRadius.circular(8)
                                              ),
                                              child: Text(
                                                timeString,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 2.0),
                                              child: Text("Scheduled: ${departure.scheduledDepartureTime}", style: TextStyle(fontSize: 13)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 2.0),
                                              child: Text(
                                                "Estimated: ${departure.estimatedDepartureTime ?? 'N/A'}",
                                                style: TextStyle(
                                                  color: TransportUtils.getColorForStatus(status.status),
                                                  fontSize: 13
                                              ),),
                                            ),
                                          ],
                                        ),
                                      )
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Divider(),
                    ],
                  ),
                ),
              ),

              SliverFillRemaining(
                hasScrollBody: true,
                fillOverscroll: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ScrollablePositionedList.builder(
                    itemScrollController: itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(0.0),
                    itemCount: _pattern.length,
                    itemBuilder: (context, index) {
                      final stopDeparture = _pattern[index];
                      final stopName = stopDeparture.stopName;
                      final departureTime = stopDeparture.scheduledDepartureTime!;

                      final timeDifference = TimeUtils.timeDifference(departureTime);

                      return Card(
                        color: index == _currentStopIndex ? Theme.of(context).colorScheme.surfaceContainerHigh : null,
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        elevation: 1,
                        child: ListTile(
                          leading: SizedBox(
                            width: 55,
                            child: Text(TransportUtils.trimTime(departureTime), style: TextStyle(fontSize: 12),),
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
