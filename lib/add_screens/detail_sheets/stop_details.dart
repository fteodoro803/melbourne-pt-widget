import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/disruption.dart';
import '../../domain/route.dart' as pt;
import '../../domain/stop.dart';
import '../../domain/trip.dart';
import '../../services/ptv_service.dart';
import '../controllers/navigation_service.dart';
import '../controllers/sheet_controller.dart';
import '../utility/search_utils.dart';
import '../widgets/departure_card.dart';
import '../overlay_sheets/trip_info.dart';
import '../widgets/sheet_header.dart';

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

  @override
  String toString() {
    return 'StopDetailsState(stop: ${stop.id}, route: ${route.id}, trips: ${trips?.length}, disruptions: ${disruptions != null})';
  }
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
  SheetController get sheetController => Get.find<SheetController>();
  final SearchUtils searchUtils = SearchUtils();
  final PtvService ptvService = Get.find<PtvService>();

  late StopDetailsState _currentState;
  late Stop _stop;
  late pt.Route _route;

  List<bool> _savedList = [];
  List<Trip> _trips = [];
  List<Disruption> _disruptions = [];

  bool _isLoading = true;
  late Timer _departureUpdateTimer;
  late StreamSubscription _sheetSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for changes to the current sheet
    _sheetSubscription = sheetController.currentSheet.listen((sheet) {
      if (sheet.name == 'Stop Details' && mounted) {
        _updateStateFromSheet(sheet);
      }
    });

    // Initialize with the current state
    _updateStateFromSheet(sheetController.currentSheet.value);

    _departureUpdateTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _updateDepartures();
    });
  }

  void _updateStateFromSheet(Sheet sheet) {
    if (sheet.state is StopDetailsState) {
      setState(() {
        _isLoading = true;
      });

      _currentState = sheet.state as StopDetailsState;
      _stop = _currentState.stop;
      _route = _currentState.route;

      if (_currentState.trips != null) {
        _trips = _currentState.trips!;
        _getSavedList();
      } else {
        _getTripList();
      }

      if (_currentState.disruptions != null) {
        _disruptions = _currentState.disruptions!;
      } else {
        _getDisruptions();
      }
    }
  }

  @override
  void dispose() {
    _departureUpdateTimer.cancel();
    _sheetSubscription.cancel();
    super.dispose();
  }

  /// Gets a list of trips for a given route and stop
  Future<void> _getTripList() async {
    List<Trip> newTripList = await searchUtils.splitDirection(_stop, _route);

    if (mounted) {
      setState(() {
        _trips = newTripList;
      });
    }

    // Update the state in the controller
    if (sheetController.currentSheet.value.state is StopDetailsState) {
      StopDetailsState state = sheetController.currentSheet.value.state;
      state.trips = _trips;
    }

    await _getSavedList();
  }

  /// Checks the favourite status of each trip
  Future<void> _getSavedList() async {
    List<bool> newSavedList = [];

    for (var trip in _trips) {
      bool isSaved = await ptvService.trips.isTripSaved(trip);
      newSavedList.add(isSaved);
    }

    if (mounted) {
      setState(() {
        _savedList = newSavedList;
        _isLoading = false;
      });
    }
  }

  /// Gets list of disruptions for route
  Future<void> _getDisruptions() async {
    List<Disruption> disruptionsList =
        await ptvService.fetchDisruptions(_route);

    if (mounted) {
      setState(() {
        _disruptions = disruptionsList;
      });
    }

    // Update the state in the controller
    if (sheetController.currentSheet.value.state is StopDetailsState) {
      StopDetailsState state = sheetController.currentSheet.value.state;
      state.disruptions = _disruptions;
    }
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
    if (_isLoading) {
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
                                      constraints:
                                          BoxConstraints(maxHeight: 500),
                                      context: context,
                                      builder: (BuildContext context) {
                                        return TripInfoSheet(
                                          route: _route,
                                          stop: _stop,
                                          disruptions: _disruptions,
                                        );
                                      },
                                    );
                                  },
                                  child: Icon(Icons.error,
                                      size: 20, color: Color(0xFFFF7308)),
                                ),
                                const SizedBox(width: 2),
                              ],
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    "To ${trip.direction?.name ?? ''}",
                                    style: TextStyle(fontSize: 17),
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
                          onTap: () => navigationService.navigateToTrip(
                              trip, _disruptions),
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Text("See all",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryFixedDim
                                          .withValues(alpha: 0.8),
                                      fontSize: 16)),
                              Icon(
                                Icons.keyboard_arrow_right,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryFixedDim
                                    .withValues(alpha: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(0.0),
                      itemCount: departures!.length > 2 ? 2 : departures.length,
                      itemBuilder: (context, index) {
                        final departure = departures[index];
                        return DepartureCard(
                            trip: trip,
                            departure: departure,
                            onDepartureTapped: (departure) {
                              navigationService.navigateToDeparture(
                                  trip, departure);
                            });
                      },
                    ),

                    // Display a message if no departures
                    if (departures.isEmpty)
                      Card(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("No departures to show."),
                        ),
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
