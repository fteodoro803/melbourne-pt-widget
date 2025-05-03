
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../domain/departure.dart';
import '../../domain/trip.dart';
import '../../ptv_service.dart';
import '../controllers/navigation_service.dart';
import '../controllers/sheet_controller.dart';
import '../utility/trip_utils.dart';
import '../utility/time_utils.dart';
import '../widgets/trip_info_widgets.dart';

class DepartureDetailsState {
  final Trip trip;
  Departure departure;

  DepartureDetailsState({
    required this.trip,
    required this.departure,
  });

  @override
  String toString() {
    return 'DepartureDetailsState(trip: ${trip.uniqueID}, departure: $departure)';
  }
}

class DepartureDetailsSheet extends StatefulWidget {
  final ScrollController scrollController;

  const DepartureDetailsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  _DepartureDetailsSheetState createState() => _DepartureDetailsSheetState();
}

class _DepartureDetailsSheetState extends State<DepartureDetailsSheet> {
  NavigationService get navigationService => Get.find<NavigationService>();
  SheetController get sheetController => Get.find<SheetController>();
  final PtvService ptvService = PtvService();

  late dynamic _initialState;
  late Departure _departure;
  late Trip _trip;

  ItemScrollController itemScrollController = ItemScrollController();
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  List<Departure> _pattern = [];
  late DepartureStatus _status;
  late String _minutesString;
  late Timer _departureUpdateTimer;

  int _currentStopIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialState = sheetController.currentSheet.value.state;

    if (_initialState != null) {
      _departure = _initialState.departure;
      _trip = _initialState.trip;

      _status = TimeUtils.getDepartureStatus(
        _departure.scheduledDepartureUTC,
        _departure.estimatedDepartureUTC,
      );
      _minutesString = TimeUtils.minutesString(_departure.estimatedDepartureUTC, _departure.scheduledDepartureUTC!);
    }

    _moveToStopIndex();

    _departureUpdateTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _updateDeparture();
    });
  }

  @override
  void dispose() {
    _departureUpdateTimer.cancel();
    super.dispose();
  }

  Future<void> _updateDeparture() async {
    if (!mounted) return;

    try {
      // await _trip.updateDepartures(departureCount: 2);
      // todo: create backend function to update only the chosen departure

      if (mounted) {
        setState(() {
          _status = TimeUtils.getDepartureStatus(
            _departure.scheduledDepartureUTC,
            _departure.estimatedDepartureUTC,
          );
          _minutesString = TimeUtils.minutesString(_departure.estimatedDepartureUTC, _departure.scheduledDepartureUTC!);
        });
      }
    } catch (e) {
      print('Error updating departures: $e');
    }
  }

  Future<void> _fetchPattern() async {
    List<Departure> newPattern = await ptvService.fetchPattern(
        _trip, _departure);

    setState(() {
      _pattern = newPattern;
    });
  }

  Future<void> _moveToStopIndex() async {
    await _fetchPattern();

    // Find the current stop index
    _currentStopIndex = _pattern.indexWhere(
      (stop) => stop.stopName?.trim().toLowerCase()
        == _trip.stop?.name.trim().toLowerCase()
    );

    // If the stop isn't found, default to 0
    if (_currentStopIndex == -1) {
      _currentStopIndex = 0;
    }

    // Get.find<SheetController>().animateSheetTo(0.4);

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

    // Add listener to the ItemPositionsListener
    itemPositionsListener.itemPositions.addListener(() {
      final firstVisibleItem = itemPositionsListener.itemPositions.value.isNotEmpty
          ? itemPositionsListener.itemPositions.value.first
          : null;

      if (firstVisibleItem != null) {
        if (firstVisibleItem.index == 0 && firstVisibleItem.itemLeadingEdge > 0) {
          widget.scrollController.jumpTo(0);
        }
      }
    });

    return CustomScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
              right: 22.0,
              bottom: 12.0,
              top: 16.0
            ),
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
                          LocationWidget(
                            textField: _trip.stop!.name,
                            textSize: 18,
                            scrollable: true),
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
                                    Text(_trip.direction!.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.1),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2),
                                    SizedBox(height: 8),
                                    RouteWidget(route: _trip.route!,
                                        scrollable: true),
                                    SizedBox(height: 4)
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),

                              DepartureTimeDetails(
                                status: _status,
                                minutesString: _minutesString,
                                departure: _departure
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
              itemPositionsListener: itemPositionsListener,
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: _pattern.length,
              itemBuilder: (context, index) {
                final stopDeparture = _pattern[index];
                final stopName = stopDeparture.stopName;
                final departureTime = stopDeparture.scheduledDepartureUTC!;
                final timeString = TimeUtils.trimTime(departureTime, false);
                final timeDifference = TimeUtils.timeDifference(departureTime);

                return Card(
                  color: index == _currentStopIndex
                      ? Theme.of(context).colorScheme.surfaceContainerHigh
                      : null,
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  elevation: 1,
                  child: ListTile(
                    leading: SizedBox(
                      width: 55,
                      child: Text(timeString, style: TextStyle(fontSize: 12)),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 5,
                          color:  TimeUtils.hasDeparted(timeDifference)
                              ? Colors.grey : Colors.green,
                          height: 60,
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Text(stopName!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,)),
                      ],
                    ),
                    onTap: () {}
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DepartureTimeDetails extends StatelessWidget {
  const DepartureTimeDetails({
    super.key,
    required DepartureStatus status,
    required String minutesString,
    required Departure departure,
  }) : _status = status, _minutesString = minutesString, _departure = departure;

  final DepartureStatus _status;
  final String _minutesString;
  final Departure _departure;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme
        .surfaceContainerHigh,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 2),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 1, horizontal: 6),
              decoration: BoxDecoration(
                color: ColourUtils.hexToColour(
                  _status.getColorString),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                _minutesString,
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
              child: Text("Scheduled: "
                "${_departure.scheduledDepartureTime}",
                style: TextStyle(fontSize: 13)),
            ),
            Padding(
              padding: EdgeInsets.only(left: 2.0),
              child: Text(
                "Estimated: ${_departure
                    .estimatedDepartureTime
                    ?? 'N/A'}",
                style: TextStyle(
                  color: ColourUtils.hexToColour(
                      _status.getColorString),
                  fontSize: 13
                )
              ),
            ),
          ],
        ),
      )
    );
  }
}
