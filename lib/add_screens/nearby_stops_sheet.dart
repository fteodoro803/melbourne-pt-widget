import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/toggle_buttons_row.dart';

import '../ptv_info_classes/route_info.dart' as pt_route;
import '../time_utils.dart';
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

  NearbyStopsState({
    required this.selectedDistance,
    required this.selectedUnit,
    required this.filters,
  });
}

class NearbyStopsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Function({int? newDistance, String? newTransportType}) onSearchFiltersChanged;
  final Function(Stop, pt_route.Route) onStopTapped;
  final Function(NearbyStopsState) onStateChanged; // New callback
  final NearbyStopsState? initialState; // New parameter

  const NearbyStopsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.onSearchFiltersChanged,
    required this.onStopTapped,
    this.initialState,
    required this.onStateChanged,
  });

  @override
  State<NearbyStopsSheet> createState() => NearbyStopsSheetState();
}

class NearbyStopsSheetState extends State<NearbyStopsSheet> {

  List<String> meterList = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"];
  List<String> kilometerList = ["1", "2", "3", "4", "5", "10"];
  late List<String> distanceList;
  List<String> distanceUnitsList = ["m", "km"];

  final String _initialSelectedMeters = "300";
  final String _initialSelectedKilometers = "5";
  final String _initialSelectedUnit = "m";

  late String _selectedDistance;
  late String _selectedUnit;

  late String _tempSelectedDistance;
  late String _tempSelectedUnit;

  late FixedExtentScrollController _distanceScrollController;
  late FixedExtentScrollController _unitScrollController;

  Set<ToggleableFilter> filters = <ToggleableFilter>{};

  bool get lowFloorFilter => filters.contains(ToggleableFilter.lowFloor);
  bool get shelterFilter => filters.contains(ToggleableFilter.shelter);

  List<Stop> _processedStops = [];
  Set<String> _expandedStopIds = {};

  @override
  void initState() {
    super.initState();

    distanceList = meterList;

    // Use initial state if available
    if (widget.initialState != null) {
      _selectedDistance = widget.initialState!.selectedDistance;
      _selectedUnit = widget.initialState!.selectedUnit;
      filters = widget.initialState!.filters;
    } else {
      _selectedDistance = _initialSelectedMeters;
      _selectedUnit = _initialSelectedUnit;
      filters = <ToggleableFilter>{};
    }

    _tempSelectedDistance = _selectedDistance;
    _tempSelectedUnit = _selectedUnit;

    // Use the correct list based on the selected unit
    distanceList = _selectedUnit == "m" ? meterList : kilometerList;

    // Initialize controllers with correct positions
    int distanceIndex = distanceList.indexOf(_selectedDistance);
    if (distanceIndex == -1) distanceIndex = 0;

    _distanceScrollController = FixedExtentScrollController(initialItem: distanceIndex);
    _unitScrollController = FixedExtentScrollController(initialItem: distanceUnitsList.indexOf(_selectedUnit));

    // Listeners for scroll controllers to update the selected items dynamically
    _distanceScrollController.addListener(() {
      setState(() {
        _tempSelectedDistance = meterList[_distanceScrollController.selectedItem];
      });
      _notifyStateChanged();
      print("Meters scroll listener triggered. Selected: $_tempSelectedDistance");
    });

    _unitScrollController.addListener(() {
      setState(() {
        _tempSelectedUnit = distanceUnitsList[_unitScrollController.selectedItem];
        distanceList = _tempSelectedUnit == "m" ? meterList : kilometerList;
        _tempSelectedDistance = _selectedUnit == "m" ? _tempSelectedDistance : _initialSelectedKilometers;
      });
      _notifyStateChanged();
      print("Unit scroll listener triggered. Selected: $_tempSelectedUnit");
    });

    _processStopsAndRoutes();
  }

  Future<void> _processStopsAndRoutes() async {
    List<Stop> processedStops = await parseStopsAndRoutes();

    if (mounted) {
      setState(() {
        _processedStops = processedStops;
      });

      // Debug to verify stops were processed correctly
      print("Processed ${_processedStops.length} unique stops");
      if (_processedStops.isNotEmpty) {
        print("First stop routes: ${_processedStops[0].routes?.length ?? 'null'}");
        print("First stop routeType: ${_processedStops[0].routeType?.type.name ?? 'null'}");
      }
    }
  }

  NearbyStopsState getCurrentState() {
    return NearbyStopsState(
      selectedDistance: _selectedDistance,
      selectedUnit: _selectedUnit,
      filters: filters,
    );
  }

  Future<List<Stop>> parseStopsAndRoutes() async {
    Set<String> uniqueStopIDs = {};
    List<Stop> uniqueStops = [];

    List<Stop> stopList = widget.arguments.searchDetails!.stops;
    List<pt_route.Route> routeList = widget.arguments.searchDetails!.routes;

    int stopIndex = 0;

    for (var stop in stopList) {
      if (!uniqueStopIDs.contains(stop.id)) {
        // Create a new stop object to avoid reference issues
        Stop newStop = Stop(
          id: stop.id,
          name: stop.name,
          latitude: stop.latitude,
          longitude: stop.longitude,
          distance: stop.distance,
          // Copy other necessary properties
        );

        newStop.routes = <pt_route.Route>[];
        newStop.routeType = routeList[stopIndex].type;

        uniqueStops.add(newStop);
        uniqueStopIDs.add(stop.id);
      }

      // Find the index of this stop in our uniqueStops list
      int uniqueStopIndex = uniqueStops.indexWhere((s) => s.id == stop.id);
      if (uniqueStopIndex != -1) {
        uniqueStops[uniqueStopIndex].routes!.add(routeList[stopIndex]);
      }

      stopIndex++;
    }

    return uniqueStops;
  }

  // Function to handle confirm button press
  onConfirmPressed() {
    Navigator.pop(context);  // Close the modal
    setState(() {
      _selectedUnit = distanceUnitsList[_unitScrollController.selectedItem];
      _selectedDistance = meterList[_distanceScrollController.selectedItem];

      // Animate the scroll to the selected item in the controller
      _distanceScrollController.animateToItem(distanceList.indexOf(_selectedDistance), duration: Duration(milliseconds: 30), curve: Curves.ease);
      _unitScrollController.animateToItem(distanceUnitsList.indexOf(_selectedUnit), duration: Duration(milliseconds: 30), curve: Curves.ease);

      print(_selectedDistance);
    });
    _notifyStateChanged();
  }

  void _notifyStateChanged() {
    widget.onStateChanged(NearbyStopsState(
      selectedDistance: _selectedDistance,
      selectedUnit: _selectedUnit,
      filters: filters,
    ));
  }

  @override
  Widget build(BuildContext context) {

    String address = widget.arguments.searchDetails!.locationController.text;

    return Column(
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

        // Address and toggleable transport type buttons
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocationWidget(textField: address, textSize: 18, scrollable: true),
              SizedBox(height: 8),
              ToggleButtonsRow(
                onTransportTypeChanged: widget.onSearchFiltersChanged,
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
                        _tempSelectedUnit = _selectedUnit;
                        _tempSelectedDistance = _selectedDistance;

                        // Determine which list to use based on current unit
                        final currentList = _selectedUnit == "m" ? meterList : kilometerList;

                        // Find the index of the current selected distance in the appropriate list
                        int distanceIndex = currentList.indexOf(_selectedDistance);
                        if (distanceIndex == -1) distanceIndex = 0; // Fallback if not found

                        // Initialize controllers with the correct current positions
                        _distanceScrollController = FixedExtentScrollController(initialItem: distanceIndex);
                        _unitScrollController = FixedExtentScrollController(
                            initialItem: distanceUnitsList.indexOf(_selectedUnit)
                        );

                        await showModalBottomSheet(
                            constraints: BoxConstraints(maxHeight: 500),
                            context: context,
                            builder: (BuildContext context) {
                              return StatefulBuilder(
                                  builder: (context, setModalState) {
                                    // Get the current distance list based on the temp selected unit
                                    final currentDistanceList = _tempSelectedUnit == "m" ? meterList : kilometerList;

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 5),
                                            child: Text("Distance:", style: TextStyle(fontSize: 18)),
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text("Within", style: TextStyle(fontSize: 22)),
                                            SizedBox(width: 8.0),
                                            Container(
                                              height: 130,
                                              width: 60,
                                              child: ListWheelScrollView.useDelegate(
                                                controller: _distanceScrollController,
                                                physics: FixedExtentScrollPhysics(),
                                                overAndUnderCenterOpacity: 0.5,
                                                itemExtent: 26,
                                                diameterRatio: 1.1,
                                                squeeze: 1.0,
                                                onSelectedItemChanged: (index) {
                                                  setModalState(() {
                                                    // Update the temp selected distance when it changes
                                                    _tempSelectedDistance = currentDistanceList[index];
                                                  });
                                                },
                                                childDelegate: ListWheelChildBuilderDelegate(
                                                  builder: (context, index) {
                                                    if (index < currentDistanceList.length) {
                                                      return Text(
                                                        currentDistanceList[index],
                                                        style: TextStyle(fontSize: 22),
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                  childCount: currentDistanceList.length,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              height: 130,
                                              width: 60,
                                              child: ListWheelScrollView.useDelegate(
                                                controller: _unitScrollController,
                                                physics: FixedExtentScrollPhysics(),
                                                overAndUnderCenterOpacity: 0.5,
                                                itemExtent: 26,
                                                diameterRatio: 1.1,
                                                squeeze: 1.0,
                                                onSelectedItemChanged: (index) {
                                                  setModalState(() {
                                                    String newUnit = distanceUnitsList[index];
                                                    if (newUnit != _tempSelectedUnit) {
                                                      _tempSelectedUnit = newUnit;

                                                      // Get the new list based on the selected unit
                                                      final newList = _tempSelectedUnit == "m" ? meterList : kilometerList;

                                                      // Set a reasonable default value in the new unit
                                                      _tempSelectedDistance = _tempSelectedUnit == "m"
                                                          ? _initialSelectedMeters
                                                          : _initialSelectedKilometers;

                                                      // Reset the distance scroll controller
                                                      _distanceScrollController.dispose();
                                                      _distanceScrollController = FixedExtentScrollController(
                                                          initialItem: newList.indexOf(_tempSelectedDistance)
                                                      );
                                                    }
                                                  });
                                                },
                                                childDelegate: ListWheelChildBuilderDelegate(
                                                  builder: (context, index) {
                                                    return Text(
                                                      distanceUnitsList[index],
                                                      style: TextStyle(fontSize: 22),
                                                    );
                                                  },
                                                  childCount: distanceUnitsList.length,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 7),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Cancel", style: TextStyle(color: Colors.grey))
                                            ),
                                            SizedBox(width: 8),
                                            ElevatedButton(
                                                onPressed: () {
                                                  setModalState(() {
                                                    // Reset to default values
                                                    _tempSelectedUnit = _initialSelectedUnit;
                                                    _tempSelectedDistance = _initialSelectedMeters;

                                                    // Update the controllers to show the default values
                                                    _distanceScrollController.dispose();
                                                    _distanceScrollController = FixedExtentScrollController(
                                                        initialItem: meterList.indexOf(_initialSelectedMeters)
                                                    );
                                                    _unitScrollController.jumpToItem(
                                                        distanceUnitsList.indexOf(_initialSelectedUnit)
                                                    );
                                                  });

                                                  setState(() {
                                                    _selectedUnit = _initialSelectedUnit;
                                                    _selectedDistance = _initialSelectedMeters;
                                                  });
                                                  _notifyStateChanged();

                                                  Navigator.pop(context);
                                                },
                                                child: Text("Use Default", style: TextStyle(color: Colors.white))
                                            ),
                                            SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () async {
                                                int distanceInMeters = (_tempSelectedUnit == "m" ? int.parse(_tempSelectedDistance) : int.parse(_tempSelectedDistance) * 1000);
                                                await widget.onSearchFiltersChanged(newTransportType: null, newDistance: distanceInMeters);
                                                setState(() {
                                                  // Save both the unit and distance values
                                                  _selectedUnit = _tempSelectedUnit;
                                                  _selectedDistance = _tempSelectedDistance;
                                                });
                                                _notifyStateChanged();
                                                Navigator.pop(context);
                                              },
                                              child: Text("Confirm"),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 45, right: 40, top: 0, bottom: 20),
                                          child: Text("\'Use Default\' automatically increases search radius until 20 results are found."),
                                        ),
                                      ],
                                    );
                                  }
                              );
                            }
                        );
                      },
                    ),
                    SizedBox(width: 5.0),
                    Wrap(
                      spacing: 5.0,
                      children:
                      ToggleableFilter.values.map((ToggleableFilter result) {
                        return FilterChip(
                            label: Text(result.name),
                            selected: filters.contains(result),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  filters.add(result);
                                } else {
                                  filters.remove(result);
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

        // List of stops
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 0.0,
              right: 16.0,
              bottom: 0.0,
              left: 16.0,
            ),
            itemCount: _processedStops.length,
            itemBuilder: (context, index) {

              final stop = _processedStops[index];
              final bool isExpanded = _expandedStopIds.contains(stop.id);

              // Debug information
              print("Stop at index $index: ${stop.id}, Routes: ${stop.routes?.length ?? 'null'}, RouteType: ${stop.routeType?.type.name ?? 'null'}");

              final routes = stop.routes ?? [];
              final stopName = stop.name;
              final distance = stop.distance;
              final routeType = stop.routeType?.type.name ?? 'unknown';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
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
                          ? Column(
                            children: [
                              LocationWidget(textField: stopName, textSize: 18, scrollable: false),
                              Align(
                                alignment: Alignment.topLeft,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    spacing: 6,
                                    children: routes.map((route) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: route.colour != null
                                              ? ColourUtils.hexToColour(route.colour!)
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          routeType == "train" || routeType == "vLine"
                                              ? route.name
                                              : route.number,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: route.textColour != null
                                                ? ColourUtils.hexToColour(route.textColour!)
                                                : Colors.black,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Column(
                            children: [
                              Row(
                                // crossAxisAlignment: CrossAxisAlignment.start,  // This aligns items to the start (top) of the row
                                children: [
                                  Icon(Icons.location_pin, size: 20),
                                  // Padding(
                                  //   padding: const EdgeInsets.only(top: 4),  // Small padding to align with first line of text
                                  //   child: Icon(Icons.location_pin, size: 20),
                                  // ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      stopName,
                                      style: TextStyle(fontSize: 18, height: 1.1),

                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.directions_walk, size: 20),
                                  SizedBox(width: 4),
                                  Text("${distance?.round()}m", style: TextStyle(fontSize: 18)),
                                ],
                              )
                            ],
                          ),
                        leading: Image.asset(
                          "assets/icons/PTV $routeType Logo.png",
                          width: 40,
                          height: 40,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Text("${distance?.round()}m", style: TextStyle(fontSize: 16)),
                            // SizedBox(width: 4),
                            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedStopIds.remove(stop.id);
                            } else {
                              _expandedStopIds.add(stop.id);
                            }
                          });
                        }
                      ),

                      if (isExpanded)
                        Divider(height: 0,),
                      if (isExpanded)
                        Container(
                        // color: Color(0xFF212325),
                        child: ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: routes.length,
                          itemBuilder: (context, routeIndex) {

                            final route = routes[routeIndex];
                            print("Route at index $routeIndex: $route");

                            return Container(

                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                trailing: Icon(Icons.keyboard_arrow_right_outlined),
                                leading: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: route.colour != null
                                        ? ColourUtils.hexToColour(route.colour!)
                                        : Colors.grey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    routeType == "train" || routeType == "vLine"
                                      ? route.name
                                      : route.number,
                                    style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: route.textColour != null
                                      ? ColourUtils.hexToColour(route.textColour!)
                                      : Colors.black,
                                    ),
                                  ),
                                ),
                                title: routeType != "train" && routeType != "vLine" ? Text(route.name) : null,
                                onTap: () async {
                                  await widget.onStopTapped(stop, route);
                                },
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}