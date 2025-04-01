import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/toggle_buttons_row.dart';

import '../ptv_info_classes/route_info.dart' as pt_route;
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

class NearbyStopsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Function({int? newDistance, String? newTransportType}) onSearchFiltersChanged;
  final Function(Stop, pt_route.Route) onStopTapped;

  const NearbyStopsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.onSearchFiltersChanged,
    required this.onStopTapped,
  });

  @override
  State<NearbyStopsSheet> createState() => _NearbyStopsSheetState();
}

class _NearbyStopsSheetState extends State<NearbyStopsSheet> {

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

  @override
  void initState() {
    super.initState();

    distanceList = meterList;

    _selectedDistance = _initialSelectedMeters;
    _tempSelectedDistance = _initialSelectedMeters;

    _selectedUnit = _initialSelectedUnit;
    _tempSelectedUnit = _initialSelectedUnit;

    _distanceScrollController = FixedExtentScrollController(initialItem: meterList.indexOf(_selectedDistance));
    _unitScrollController = FixedExtentScrollController(initialItem: distanceUnitsList.indexOf(_selectedUnit));

    // Listeners for scroll controllers to update the selected items dynamically
    _distanceScrollController.addListener(() {
      setState(() {
        _tempSelectedDistance = meterList[_distanceScrollController.selectedItem];
      });
      print("Meters scroll listener triggered. Selected: $_tempSelectedDistance");
    });

    _unitScrollController.addListener(() {
      setState(() {
        _tempSelectedUnit = distanceUnitsList[_unitScrollController.selectedItem];
        distanceList = _tempSelectedUnit == "m" ? meterList : kilometerList;
        _tempSelectedDistance = _selectedUnit == "m" ? _tempSelectedDistance : _initialSelectedKilometers;
      });
      print("Unit scroll listener triggered. Selected: $_tempSelectedUnit");
    });
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
            itemCount: widget.arguments.searchDetails!.stops.length,
            itemBuilder: (context, index) {

              if (index >= widget.arguments.searchDetails!.routes.length) {
                return Container();
              }

              final route = widget.arguments.searchDetails!.routes[index];
              final stopName = widget.arguments.searchDetails!.stops[index].name;
              final routeName = widget.arguments.searchDetails!.routes[index].name;
              final distance = widget.arguments.searchDetails!.stops[index].distance;
              final routeType = widget.arguments.searchDetails!.routes[index].type.type.name;

              return Card(
                child: ListTile(
                  // Distance in meters from marker
                  trailing: Text("${distance?.round()}m", style: TextStyle(fontSize: 16)),

                  // Stop and route details
                  title: Column(
                    children: [
                      LocationWidget(textField: stopName, textSize: 16, scrollable: true),
                      SizedBox(height: 4),
                      RouteWidget(route: route, scrollable: true),
                      if (routeType != "train" && routeType != "vLine")
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            routeName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),

                  // Render stop details sheet if stop is tapped
                  onTap: () async {
                    await widget.onStopTapped(widget.arguments.searchDetails!.stops[index], widget.arguments.searchDetails!.routes[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}