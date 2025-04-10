import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../ptv_info_classes/route_info.dart' as pt_route;
import '../widgets/distance_filter.dart';
import '../widgets/screen_widgets.dart' as ScreenWidgets;
import '../widgets/transport_widgets.dart';

enum ToggleableFilter {
  lowFloor(name: "Low Floor"),
  shelter(name: "Shelter");

  final String name;

  const ToggleableFilter({required this.name});
}

enum DistanceFilter {
  meters(name: "m"),
  kilometers(name: "km");

  final String name;

  const DistanceFilter({required this.name});
}

class NearbyStopsState {
  final String selectedDistance;
  final String selectedUnit;
  final Set<ToggleableFilter> filters;
  final Map<String, bool> transportTypeFilters;
  final int savedScrollIndex;

  NearbyStopsState({
    required this.selectedDistance,
    required this.selectedUnit,
    required this.filters,
    required this.transportTypeFilters,
    required this.savedScrollIndex,
  });
}

class NearbyStopsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Function({int? newDistance, String? newTransportType}) onSearchFiltersChanged;
  final Function(Stop, pt_route.Route) onStopTapped;
  final Function(NearbyStopsState) onStateChanged; // New callback
  final NearbyStopsState? initialState; // New parameter
  final bool shouldResetFilters;


  const NearbyStopsSheet({
    Key? key,
    required this.arguments,
    required this.scrollController,
    required this.onSearchFiltersChanged,
    required this.onStopTapped,
    this.initialState,
    required this.onStateChanged,
    this.shouldResetFilters = false,
  }) : super(key: key);

  @override
  State<NearbyStopsSheet> createState() => NearbyStopsSheetState();
}

class NearbyStopsSheetState extends State<NearbyStopsSheet> {

  late String _selectedDistance;
  late String _selectedUnit;

  Set<ToggleableFilter> _filters = <ToggleableFilter>{};

  bool get lowFloorFilter => _filters.contains(ToggleableFilter.lowFloor);
  bool get shelterFilter => _filters.contains(ToggleableFilter.shelter);

  late Map<String, bool> _transportTypeFilters = {};
  late int _savedScrollIndex;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();


  @override
  void initState() {
    super.initState();

    // Use initial state if available
    if (widget.initialState != null) {
      _selectedDistance = widget.initialState!.selectedDistance;
      _selectedUnit = widget.initialState!.selectedUnit;
      _filters = widget.initialState!.filters;
      _transportTypeFilters = widget.initialState!.transportTypeFilters;
      _savedScrollIndex = widget.initialState!.savedScrollIndex;
    } else {
      _selectedDistance = "300";
      _selectedUnit = "m";
      _filters = <ToggleableFilter>{};
      _transportTypeFilters = {
        "all": true,
        "tram": false,
        "bus": false,
        "train": false,
        "vLine": false
      };
      _savedScrollIndex = 0;
    }
    scrollToStopItem(_savedScrollIndex);
  }

  @override
  void didUpdateWidget(NearbyStopsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldResetFilters && !oldWidget.shouldResetFilters) {
      // Reset filters to default values
      setState(() {
        _selectedDistance = "300";
        _selectedUnit = "m";
        _filters = <ToggleableFilter>{};
        _transportTypeFilters = {
          "all": true,
          "tram": false,
          "bus": false,
          "train": false,
          "vLine": false
        };
        _savedScrollIndex = 0;
        _itemScrollController.jumpTo(
            index: 0,
            alignment: 0
        );
      });
    }
  }

  void scrollToStopItem(int stopIndex) {
    setState(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
              index: stopIndex,
              duration: Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              alignment: 0
          );
        }
      });
    });
  }

  NearbyStopsState getCurrentState() {
    return NearbyStopsState(
      selectedDistance: _selectedDistance,
      selectedUnit: _selectedUnit,
      filters: _filters,
      transportTypeFilters: _transportTypeFilters,
      savedScrollIndex: _savedScrollIndex,
    );
  }

  Future<void> onConfirmPressed(String selectedDistance, String selectedUnit) async {
    int distanceInMeters = (selectedUnit == "m" ? int.parse(selectedDistance) : int.parse(selectedDistance) * 1000);

    setState(() {
      _selectedUnit = selectedUnit;
      _selectedDistance = selectedDistance;
      widget.onSearchFiltersChanged(newTransportType: null, newDistance: distanceInMeters);
    });
    _notifyStateChanged();
  }

  void _notifyStateChanged() {
    widget.onStateChanged(NearbyStopsState(
      selectedDistance: _selectedDistance,
      selectedUnit: _selectedUnit,
      filters: _filters,
      transportTypeFilters: _transportTypeFilters,
      savedScrollIndex: _savedScrollIndex,
    ));
  }

  void _handleTransportToggle(String transportType) {
    bool wasSelected = _transportTypeFilters[transportType]!;
    String newTransportToggled;

    if (!(wasSelected && transportType == "all")) {
      if (wasSelected) {
        widget.onSearchFiltersChanged(
            newTransportType: "all", newDistance: null);
        newTransportToggled = "all";
      }
      else {
        widget.onSearchFiltersChanged(
            newTransportType: transportType, newDistance: null);
        newTransportToggled = transportType;
      }

      setState(() {
        for (var entry in _transportTypeFilters.entries) {
          String type = entry.key;
          if (type == newTransportToggled) {
            _transportTypeFilters[type] = true;
          }
          else {
            _transportTypeFilters[type] = false;
          }
        }
      });
      _notifyStateChanged();
    }
  }

  @override
  Widget build(BuildContext context) {

    String address = widget.arguments.searchDetails!.locationController.text;

    // Add listener to the ItemPositionsListener
    _itemPositionsListener.itemPositions.addListener(() {
      final firstVisibleItem = _itemPositionsListener.itemPositions.value.isNotEmpty
          ? _itemPositionsListener.itemPositions.value.first
          : null;

      if (firstVisibleItem != null) {
        if (firstVisibleItem.index == 0 && firstVisibleItem.itemLeadingEdge > 0) {
          widget.scrollController.jumpTo(0);
        }
      }
    });

    return Column(
      children: [
        // Draggable Scrollable Sheet Handle
        if (!widget.arguments.searchDetails!.isSheetExpanded)
          ScreenWidgets.HandleWidget(),
        // Address and toggleable transport type buttons
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
                      LocationWidget(textField: address, textSize: 18, scrollable: true),
                      SizedBox(height: 8),
                      Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: _transportTypeFilters.keys.map((transportType) {
                          final isSelected = _transportTypeFilters[transportType] ?? false;
                          return ScreenWidgets.TransportToggleButton(
                            isSelected: isSelected,
                            transportType: transportType,
                            handleTransportToggle: _handleTransportToggle,
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 4),
                      Divider(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              avatar: Icon(Icons.keyboard_arrow_down_sharp),
                              label: Text('Within $_selectedDistance$_selectedUnit'),
                              onPressed: () async {
                                await showModalBottomSheet(
                                  constraints: BoxConstraints(maxHeight: 500),
                                  context: context,
                                  builder: (BuildContext context) {
                                    return DistanceFilterSheet(
                                      selectedDistance: _selectedDistance,
                                      selectedUnit: _selectedUnit,
                                      onConfirmPressed: onConfirmPressed,
                                    );
                                });
                              },

                            ),
                            SizedBox(width: 5.0),
                            Wrap(
                              spacing: 5.0,
                              children:
                              ToggleableFilter.values.map((ToggleableFilter result) {
                                return FilterChip(
                                    label: Text(result.name),
                                    selected: _filters.contains(result),
                                    onSelected: (bool selected) {
                                      setState(() {
                                        if (selected) {
                                          _filters.add(result);
                                        } else {
                                          _filters.remove(result);
                                        }
                                      });
                                    }
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Header item

              SliverFillRemaining(
                hasScrollBody: true,
                fillOverscroll: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(0.0),
                    itemCount: widget.arguments.searchDetails!.stops.length,
                    itemBuilder: (context, index) {
                      // Stop items
                      final stopIndex = index;
                      final stop = widget.arguments.searchDetails!.stops[stopIndex];
                      final bool? isExpanded = stop.isExpanded;
                      final routes = stop.routes ?? [];
                      final stopName = stop.name;
                      final distance = stop.distance;
                      final routeType = stop.routeType?.name ?? 'unknown';

                      return Card(
                        color: isExpanded! ? Theme.of(context).colorScheme.surfaceContainerHigh : null,
                        margin: EdgeInsets.only(bottom: isExpanded ? 12 : 4, top: 8, left: 0, right: 0),
                        child: ListTile(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                          dense: true,
                          contentPadding: EdgeInsets.all(0),
                          // Stop and route details
                          title: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                dense: true,
                                visualDensity: VisualDensity(horizontal: -3, vertical: 0),
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                title: !isExpanded
                                    ? UnexpandedStopWidget(stopName: stopName, routes: routes, routeType: routeType)
                                    : ExpandedStopWidget(stopName: stopName, distance: distance),
                                leading: Image.asset(
                                  "assets/icons/PTV $routeType Logo.png",
                                  width: 40,
                                  height: 40,
                                ),
                                trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                onTap: () {
                                  setState(() {
                                    _savedScrollIndex = stopIndex;
                                    widget.arguments.searchDetails?.stops[stopIndex].isExpanded = !widget.arguments.searchDetails!.stops[stopIndex].isExpanded!;
                                  });
                                  _notifyStateChanged();
                                }
                              ),

                              if (isExpanded)...[
                                Divider(height: 0,),
                                ExpandedStopRoutesWidget(routes: routes, routeType: routeType, onStopTapped: widget.onStopTapped, stop: stop),
                              ],
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