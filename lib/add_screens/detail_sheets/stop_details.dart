import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/disruption.dart';
import '../../domain/route.dart' as pt;
import '../../domain/stop.dart';
import '../../domain/trip.dart';
import '../../ptv_service.dart';
import '../controllers/navigation_service.dart';
import '../utility/search_utils.dart';
import '../widgets/departure_card.dart';
import '../overlay_sheets/trip_info.dart';
import '../widgets/new_widgets.dart';

class StopDetailsState {
  final Stop stop;
  final pt.Route route;
  List<Trip>? trips;
  List<Disruption>? disruptions;

  StopDetailsState({
    required this.stop,
    required this.route,
    this.trips,
    this.disruptions,
  });
}

class StopDetailsSheet extends StatefulWidget {
  final ScrollController scrollController;

  const StopDetailsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  _StopDetailsSheetState createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<StopDetailsSheet> {
  NavigationService get navigationService => Get.find<NavigationService>();
  final SearchUtils searchUtils = SearchUtils();
  final PtvService ptvService = PtvService();

  late dynamic _initialState;
  late Stop _stop;
  late pt.Route _route;

  List<bool> _savedList = [];
  List<Trip> _trips = [];
  List<Disruption> _disruptions = [];
  late StopDetailsState _state;

  bool _isSavedListInitialized = false;
  late Timer _departureUpdateTimer;

  @override
  void initState() {
    super.initState();

    _initialState = navigationService.stateToPush;

    if (_initialState != null) {
      _stop = _initialState.stop;
      _route = _initialState.route;

      _state = StopDetailsState(stop: _stop, route: _route);

      if (_initialState.trips != null) {
        _trips = _initialState.trips;
        _state.trips = _trips;
        _getSavedList();
      } else {
        _getTripList();
      }

      if (_initialState.disruptions != null) {
        _disruptions = _initialState.disruptions;
        _state.disruptions = _disruptions;
      } else {
        _getDisruptions();
      }
    }

    _departureUpdateTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _updateDepartures();
    });
  }

  @override
  void dispose() {
    _departureUpdateTimer.cancel();
    super.dispose();
  }

  /// Gets a list of trips for a given route and stop
  Future<void> _getTripList() async {
    List<Trip> newTripList = await searchUtils.splitDirection(_stop, _route);
    _trips = newTripList;
    _state.trips = _trips;

    await _getSavedList();
  }

  /// Checks the favourite status of each trip
  Future<void> _getSavedList() async {
    List<bool> newSavedList = [];

    for (var trip in _trips) {
      bool isSaved = await ptvService.isTripSaved(trip);
      newSavedList.add(isSaved);
    }

    setState(() {
      _savedList = newSavedList;
      _isSavedListInitialized = true;
    });
  }

  /// Gets list of disruptions for route
  Future<void> _getDisruptions() async {
    List<Disruption> disruptionsList = await ptvService.fetchDisruptions(_route);
    setState(() {
      _disruptions = disruptionsList;
      _state.disruptions = disruptionsList;
    });
  }

  /// Updates the departures for each trip
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

  /// Callback function to add trip to favourites
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

  @override
  Widget build(BuildContext context) {

    if (!_isSavedListInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.zero,
      controller: widget.scrollController,
      physics: ClampingScrollPhysics(),
      children: [
        RouteHeaderWidget(
          showDirection: false,
          stop: _stop,
          route: _route,
          trips: _trips,
          disruptions: _disruptions,
          state: _state,
          savedList: _savedList,
          handleSave: _onConfirmPressed,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
          child: Column(
            children: _trips.map((trip) {
              var departures = trip.departures;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
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
                                      constraints: BoxConstraints(maxHeight: 500),
                                      context: context,
                                      builder: (BuildContext context) {
                                        return TripInfoSheet(
                                          route: _route,
                                          stop: _stop,
                                          disruptions: _disruptions,
                                          state: _state,
                                        );
                                      },
                                    );
                                  },
                                  child: Icon(Icons.warning_outlined, color: Color(0xFFF6833C)),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    "Towards ${trip.direction?.name ?? ''}",
                                    style: TextStyle(fontSize: 18),
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
                          onTap: () => navigationService
                              .navigateToTrip(trip, _disruptions, _state),
                          child: Row(
                            children: [
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
                      padding: EdgeInsets.all(0.0),
                      itemCount: departures!.length > 2
                        ? 2 : departures.length,
                      itemBuilder: (context, index) {
                        final departure = departures[index];
                        return DepartureCard(
                          trip: trip,
                          departure: departure,
                          onDepartureTapped: (departure) {
                            navigationService
                                .navigateToDeparture(trip, departure, _state);
                          });
                      },
                    ),

                    // Display a message if no departures
                    if (departures.isEmpty)
                      Card(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        elevation: 1,
                        child: Text("No departures to show."),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}