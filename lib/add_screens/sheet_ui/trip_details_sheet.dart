import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:get/get.dart';
import '../../domain/departure.dart';
import '../../domain/disruption.dart';
import '../../domain/trip.dart';
import '../../ptv_service.dart';
import '../controllers/search_controller.dart' as search_controller;
import '../utility/search_utils.dart';
import '../widgets/departure_card.dart';
import '../widgets/trip_widgets.dart';
import '../widgets/trip_details.dart';

class TripDetailsSheet extends StatefulWidget {
  final Trip trip;
  final List<Disruption>? disruptions;
  final ScrollController scrollController;

  const TripDetailsSheet({
    super.key,
    required this.trip,
    required this.disruptions,
    required this.scrollController,
  });

  @override
  _TripDetailsSheetState createState() => _TripDetailsSheetState();
}

class _TripDetailsSheetState extends State<TripDetailsSheet> {
  PtvService ptvService = PtvService();
  SearchUtils searchUtils = SearchUtils();

  late Trip _trip;
  late bool _isSaved;
  late List<Disruption> _disruptions;
  Map<String, bool> _filters = {}; // todo: initialize these!
  late List<Departure> _filteredDepartures;
  late Timer _departureUpdateTimer;

  bool _areDisruptionsInitialized = false;

  @override
  void initState() {
    super.initState();

    _trip = widget.trip;
    _filteredDepartures = widget.trip.departures!;
    _checkSaved();
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

  Future<void> _updateDepartures() async {
    if (!mounted) return;

    try {
      await _trip.updateDepartures(departureCount: 2);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error updating departures: $e');
    }
  }

  void _setFilters(String key) {
    _filters[key] = !_filters[key]!;
    if (_filters['Low Floor'] == true) {
      _filteredDepartures = _filteredDepartures.where(
        (departure) => departure.hasLowFloor
        == _filters['Low Floor']).toList();
    }
  }

  Future<void> _getDisruptions() async {
    List<Disruption> disruptionsList = widget.disruptions != null
        ? widget.disruptions!
        : await ptvService.fetchDisruptions(widget.trip.route!);
    setState(() {
      _disruptions = disruptionsList;
      _areDisruptionsInitialized = true;
    });
  }

  Future<void> _handleSave() async {
    _isSaved = !_isSaved;
    searchUtils.handleSave(widget.trip);
  }

  Future<void> _checkSaved() async {
    _isSaved = await ptvService.isTripSaved(widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    if (!_areDisruptionsInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 22.0, bottom: 12.0, top: 16.0),
              child: Column(
                children: [
                  LocationWidget(textField: trip.stop!.name, textSize: 18, scrollable: true),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 67,
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
                            Row(
                              children: [
                                if (_disruptions.isNotEmpty)...[
                                  GestureDetector(
                                    child: Icon(Icons.warning_outlined, color: Color(
                                        0xFFF6833C)),
                                    onTap: () async {
                                      await showModalBottomSheet(
                                        constraints: BoxConstraints(maxHeight: 500),
                                        context: context,
                                        builder: (BuildContext context) {
                                          return TripDetails(
                                            route: trip.route!,
                                            stop: trip.stop!,
                                            disruptions: _disruptions
                                          );
                                        }
                                      );
                                    },
                                  ),
                                  SizedBox(width: 2),
                                ],
                                Text("Towards ${trip.direction!.name}",
                                    style: TextStyle(
                                        fontSize: 16,
                                        height: 1.4
                                    )
                                ),
                              ],
                            ),

                            ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                              dense: true,
                              title: RouteWidget(route: trip.route!, scrollable: true),
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
                                              route: trip.route!,
                                              stop: trip.stop!,
                                              disruptions: _disruptions
                                            );
                                          }
                                        );
                                      },
                                    ),

                                    SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        _handleSave();
                                        SaveTripService.renderSnackBar(context, _isSaved);
                                      },
                                      child: Icon(
                                        _isSaved ? Icons.star : Icons.star_border,
                                        size: 30,
                                        color: _isSaved ? Colors.yellow : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 5.0,
                    children: _filters.entries.map((MapEntry<String,bool> filter) {
                      return FilterChip(
                          label: Text(filter.key),
                          selected: filter.value,
                          onSelected: (bool selected) {
                            _setFilters(filter.key);
                          }
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 12),
                  Divider(height: 0),
                ],
              ),
            ),
          ),

          // Suburb sticky headers + stops
          SliverStickyHeader(
            header: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  // color: Theme.of(context).colorScheme.surfaceContainerLow,
                  padding: EdgeInsets.only(left: 18, right: 18, top: 4, bottom: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upcoming Departures",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 2),
              ],
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final departure = _filteredDepartures[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: DepartureCard(
                    trip: trip,
                    departure: departure,
                    onDepartureTapped: (departure) {
                      Get.find<search_controller.SearchController>().pushDeparture(departure);
                  }),
                );
              },
              childCount: _filteredDepartures.length,
            )),
          ),
        ],
      );
  }
}