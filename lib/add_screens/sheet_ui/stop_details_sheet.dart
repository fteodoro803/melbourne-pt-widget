import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/disruption.dart';
import '../../domain/route.dart' as pt_route;
import '../../domain/stop.dart';
import '../../domain/trip.dart';
import '../../ptv_service.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../utility/search_utils.dart';
import '../widgets/departure_card.dart';
import '../widgets/save_trip_sheet.dart';
import '../widgets/trip_details.dart';
import '../widgets/trip_widgets.dart';

class StopDetailsSheet extends StatefulWidget {
  final Stop stop;
  final pt_route.Route route;
  final ScrollController scrollController;

  const StopDetailsSheet({
    super.key,
    required this.stop,
    required this.route,
    required this.scrollController,
  });

  @override
  _StopDetailsSheetState createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<StopDetailsSheet> {
  SearchUtils searchUtils = SearchUtils();
  PtvService ptvService = PtvService();

  bool _isSavedListInitialized = false;
  List<bool> _savedList = [];
  List<Trip> _trips = [];
  List<Disruption> _disruptions = [];

  late Timer _departureUpdateTimer;

  @override
  void initState() {
    super.initState();

    _getTripList();
    _getDisruptions();

    _departureUpdateTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _updateDepartures();
    });
  }

  @override
  void dispose() {
    _departureUpdateTimer.cancel();
    super.dispose();
  }

  Future<void> _getTripList() async {
    List<Trip> newTripList = await searchUtils.splitDirection(widget.stop, widget.route);
    List<bool> newSavedList = [];

    for (var trip in newTripList) {
      bool isSaved = await ptvService.isTripSaved(trip);
      newSavedList.add(isSaved);
    }

    setState(() {
      _savedList = newSavedList;
      _trips = newTripList;
      _isSavedListInitialized = true;
    });
  }

  Future<void> _updateDepartures() async {
    if (!mounted) return;

    try {
      for (var trip in _trips) {
        await trip.updateDepartures(departureCount: 2);
      }

      // Force refresh
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error updating departures: $e');
    }
  }

  Future<void> _onConfirmPressed(List<bool> tempSavedList) async {
    for (var trip in _trips) {
      int index = _trips.indexOf(trip);
      bool wasSaved = _savedList[index];
      bool isNowSaved = tempSavedList[index];
      if (wasSaved != isNowSaved) {
        await searchUtils.handleSave(trip);
      }
    }
    setState(() {
      _savedList = tempSavedList;
    });
  }

  Future<void> _getDisruptions() async {
    List<Disruption> disruptionsList = await ptvService.fetchDisruptions(widget.route);
    setState(() {
      _disruptions = disruptionsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final route = widget.route;

    if (!_isSavedListInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView(
        padding: EdgeInsets.zero,
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationWidget(textField: stop.name,
                    textSize: 18,
                    scrollable: true),

                // Stop location
                ListTile(
                  contentPadding: EdgeInsets.all(0),
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  title: Row(
                    children: [
                      SizedBox(width: 8),
                      Container(
                        width: 4,

                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Color(0xFF717171),
                        ),
                      ),
                      SizedBox(width: 10),
                      RouteWidget(route: route, scrollable: false),
                    ],
                  ),
                  trailing: SizedBox(
                    width: 63,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Icon(Icons.info, color: Color(
                              0xFF4F82FF), size: 27),
                          onTap: () async {
                            await showModalBottomSheet(
                                constraints: BoxConstraints(maxHeight: 500),
                                context: context,
                                builder: (BuildContext context) {
                                  return TripDetails(
                                      route: route,
                                      stop: stop,
                                      disruptions: _disruptions
                                  );
                                }
                            );
                          },
                        ),

                        SizedBox(width: 4),
                        GestureDetector(
                          child: FavoriteButton(isSaved: _savedList.contains(true)),
                          onTap: () async {
                            if (_trips.length > 1) {
                              await showModalBottomSheet(
                                constraints: BoxConstraints(maxHeight: 320),
                                context: context,
                                builder: (BuildContext context) {
                                  return SaveTripSheet(
                                    savedList: _savedList,
                                    route: route,
                                    stop: stop,
                                    tripList: _trips,
                                    onConfirmPressed: _onConfirmPressed,
                                  );
                                }
                              );
                            } else {
                              List<bool> tempSavedList = [..._savedList];
                              tempSavedList[0] = !tempSavedList[0];
                              await _onConfirmPressed(tempSavedList);
                              SaveTripService.renderSnackBar(context, tempSavedList[0]);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                ),

                Divider(),

                // Departures for each direction
                Column(
                  children: _trips.map((transport) {
                    var departures = transport.departures;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left section: Warning icon + scrollable "Towards..." text
                              Expanded(
                                child: Row(
                                  children: [
                                    if (_disruptions.isNotEmpty) ...[
                                      GestureDetector(
                                        onTap: () async {
                                          await showModalBottomSheet(
                                            constraints: const BoxConstraints(maxHeight: 500),
                                            context: context,
                                            builder: (BuildContext context) {
                                              return TripDetails(
                                                route: route,
                                                stop: stop,
                                                disruptions: _disruptions,
                                              );
                                            },
                                          );
                                        },
                                        child: const Icon(Icons.warning_outlined, color: Color(0xFFF6833C)),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          "Towards ${transport.direction?.name ?? ''}",
                                          style: const TextStyle(fontSize: 18),
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right section: "See all >"
                              GestureDetector(
                                onTap: () =>
                                    Get.find<search_controller.SearchController>().pushTrip(transport),
                                child: Row(
                                  children: const [
                                    SizedBox(width: 4),
                                    Text("See all", style: TextStyle(fontSize: 16)),
                                    Icon(Icons.keyboard_arrow_right),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(0.0),
                            itemCount: departures!.length > 2 ? 2 : departures
                                .length,
                            itemBuilder: (context, index) {
                              final departure = departures[index];
                              return DepartureCard(
                                  trip: transport,
                                  departure: departure,
                                  onDepartureTapped: (departure) {
                                    Get.find<search_controller.SearchController>().setTrip(transport);
                                    Get.find<search_controller.SearchController>().pushDeparture(departure);
                                  });
                            },
                          ),

                          // Display a message if no departures
                          if (departures.isEmpty)
                            Card(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              elevation: 1,
                              child: Text("No departures to show."),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      );

  }
}