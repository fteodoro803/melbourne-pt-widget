import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:get/get.dart';
import '../../domain/departure.dart';
import '../../domain/disruption.dart';
import '../../domain/trip.dart';
import '../../services/ptv_service.dart';
import '../controllers/navigation_service.dart';
import '../controllers/sheet_controller.dart';
import '../utility/search_utils.dart';
import '../widgets/departure_card.dart';
import '../widgets/sheet_header.dart';

class TripDetailsState {
  final Trip trip;
  List<Disruption>? disruptions;
  Map<String, bool>? filters;

  TripDetailsState({
    required this.trip,
    this.disruptions,
    this.filters,
  });

  @override
  String toString() {
    return 'TripDetailsState(trip: ${trip.uniqueID}, filters: $filters, disruptions: ${disruptions != null})';
  }
}

class TripDetailsSheet extends StatefulWidget {
  final ScrollController scrollController;

  const TripDetailsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  _TripDetailsSheetState createState() => _TripDetailsSheetState();
}

class _TripDetailsSheetState extends State<TripDetailsSheet> {
  final NavigationService navigationService = Get.find<NavigationService>();
  SheetController get sheetController => Get.find<SheetController>();
  late dynamic _initialState;

  PtvService ptvService = PtvService();
  SearchUtils searchUtils = SearchUtils();

  late Trip _trip;
  late bool _isSaved;
  bool _isSavedInitialized = false;
  late List<Disruption> _disruptions;
  Map<String, bool> _filters = {}; // todo: initialize these!
  late List<Departure> _allDepartures;
  late List<Departure> _filteredDepartures;

  late Timer _departureUpdateTimer;

  bool _areDisruptionsInitialized = false;

  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _initialState = sheetController.currentSheet.value.state;

    if (_initialState != null) {
      _trip = _initialState.trip;
      _allDepartures = _initialState.trip.departures;
      _filteredDepartures = _allDepartures;

      if (_initialState.disruptions != null) {
        _disruptions = _initialState.disruptions;
        _areDisruptionsInitialized = true;
      } else {
        _getDisruptions();
      }
    }

    _filters = {
      'Low Floor': false,
      'Air Conditioning': false,
    };

    _checkSaved();

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
    setState(() {
      _filters[key] = !_filters[key]!;
      if (_filters[key] == true) {
      _filteredDepartures = _allDepartures.where(
        (departure) => departure.hasLowFloor
        == _filters[key]).toList();
      } else {
        _filteredDepartures = _allDepartures;
      }
    });
  }

  Future<void> _getDisruptions() async {
    List<Disruption> disruptionsList = await ptvService.fetchDisruptions(_initialState.trip.route!);
    setState(() {
      sheetController.currentSheet.value.state.disruptions = disruptionsList;
      _disruptions = disruptionsList;
      _areDisruptionsInitialized = true;
    });
  }

  Future<void> _handleSave(List<bool> list) async {
    setState(() {
      _isSaved = !_isSaved;
    });
    searchUtils.handleSave(_initialState.trip);
  }

  Future<void> _checkSaved() async {
    bool isSaved = await ptvService.trips.isTripSaved(_initialState.trip);
    setState(() {
      _isSaved = isSaved;
      _isSavedInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (!_areDisruptionsInitialized || !_isSavedInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: RouteHeaderWidget(
            showDirection: true,
            stop: _trip.stop!,
            route: _trip.route!,
            trips: [_trip],
            disruptions: _disruptions,
            savedList: [_isSaved],
            handleSave: _handleSave,
          ),
        ),

        // Suburb sticky headers + stops
        SliverStickyHeader(
          header: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: EdgeInsets.only(left: 18, right: 12, top: 0, bottom: 0),
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Upcoming Departures",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: GestureDetector(
                        child: SizedBox(
                          width: 70,
                          child: Row(
                            children: [
                              Text("Filters", style: TextStyle(fontSize: 14)),
                              Icon(!_showFilters ? Icons.arrow_drop_down : Icons.arrow_drop_up)
                            ],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        }
                      )
                    ),
                    if (_showFilters) ...[
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
                      SizedBox(height: 4)
                    ]
                  ],
                ),
              ),
            ],
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final departure = _filteredDepartures[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: DepartureCard(
                  trip: _trip,
                  departure: departure,
                  onDepartureTapped: (departure) {
                    navigationService
                        .navigateToDeparture(_trip, departure);
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