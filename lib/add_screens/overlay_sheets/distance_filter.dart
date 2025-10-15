import 'package:flutter/material.dart';

class DistanceFilterSheet extends StatefulWidget {
  final String selectedDistance;
  final String selectedUnit;
  final Function(String, String) onConfirmPressed;

  const DistanceFilterSheet(
      {super.key,
      required this.selectedDistance,
      required this.selectedUnit,
      required this.onConfirmPressed});

  @override
  _DistanceFilterSheetState createState() => _DistanceFilterSheetState();
}

class _DistanceFilterSheetState extends State<DistanceFilterSheet> {
  late FixedExtentScrollController _distanceScrollController;
  late FixedExtentScrollController _unitScrollController;

  final String _initialSelectedMeters = "300";
  final String _initialSelectedKilometers = "5";
  final String _initialSelectedUnit = "m";

  List<String> meterList = [
    "50",
    "100",
    "200",
    "300",
    "400",
    "500",
    "600",
    "700",
    "800",
    "900"
  ];
  List<String> kilometerList = ["1", "2", "3", "4", "5", "10"];
  List<String> distanceUnitsList = ["m", "km"];

  late String _tempSelectedDistance;
  late String _tempSelectedUnit;
  late int _currentDistanceIndex;

  @override
  void initState() {
    super.initState();

    _tempSelectedUnit = widget.selectedUnit;
    _tempSelectedDistance = widget.selectedDistance;

    // Use the correct list based on the selected unit
    List<String> currentDistanceList =
        _tempSelectedUnit == "m" ? meterList : kilometerList;

    // Initialize controllers with correct positions
    _currentDistanceIndex = currentDistanceList.indexOf(_tempSelectedDistance);
    if (_currentDistanceIndex == -1) _currentDistanceIndex = 0;

    _distanceScrollController =
        FixedExtentScrollController(initialItem: _currentDistanceIndex);
    _unitScrollController = FixedExtentScrollController(
        initialItem: distanceUnitsList.indexOf(_tempSelectedUnit));
  }

  @override
  void dispose() {
    _distanceScrollController.dispose();
    _unitScrollController.dispose();
    super.dispose();
  }

  // Helper method to get current distance list
  List<String> getCurrentDistanceList(String unit) {
    return unit == "m" ? meterList : kilometerList;
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setModalState) {
      // Get the current distance list based on the temp selected unit
      final currentDistanceList = getCurrentDistanceList(_tempSelectedUnit);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 40, right: 40, top: 20, bottom: 5),
              child: Text("Distance:", style: TextStyle(fontSize: 18)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Within", style: TextStyle(fontSize: 22)),
              SizedBox(width: 8.0),
              SizedBox(
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
                      _currentDistanceIndex = index;
                      // Update the selected distance with current list's value
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
              SizedBox(
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
                    String newUnit = distanceUnitsList[index];

                    if (newUnit != _tempSelectedUnit) {
                      // Create a new controller for the distance wheel
                      FixedExtentScrollController newController;
                      String defaultValue;

                      // Set default values based on new unit
                      if (newUnit == "m") {
                        defaultValue = _initialSelectedMeters;
                      } else {
                        defaultValue = _initialSelectedKilometers;
                      }

                      // Get the appropriate list and find index
                      List<String> newList = getCurrentDistanceList(newUnit);
                      int defaultIndex = newList.indexOf(defaultValue);
                      if (defaultIndex == -1) defaultIndex = 0;

                      // Create new controller at the default position
                      newController = FixedExtentScrollController(
                          initialItem: defaultIndex);

                      setModalState(() {
                        // Update unit
                        _tempSelectedUnit = newUnit;

                        // Update distance
                        _tempSelectedDistance = defaultValue;
                        _currentDistanceIndex = defaultIndex;

                        // Dispose old controller and assign new one
                        _distanceScrollController.dispose();
                        _distanceScrollController = newController;
                      });
                    }
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
                  child: Text("Cancel", style: TextStyle(color: Colors.grey))),
              SizedBox(width: 8),
              ElevatedButton(
                  onPressed: () {
                    // Create new controller for the reset
                    FixedExtentScrollController newController =
                        FixedExtentScrollController(
                            initialItem:
                                meterList.indexOf(_initialSelectedMeters));

                    setModalState(() {
                      // Reset to default values
                      _tempSelectedUnit = _initialSelectedUnit;
                      _tempSelectedDistance = _initialSelectedMeters;

                      // Update unit controller
                      _unitScrollController.jumpToItem(
                          distanceUnitsList.indexOf(_initialSelectedUnit));

                      // Replace distance controller
                      _distanceScrollController.dispose();
                      _distanceScrollController = newController;
                    });

                    widget.onConfirmPressed(
                        _initialSelectedMeters, _initialSelectedUnit);
                    Navigator.pop(context);
                  },
                  child: Text("Use Default",
                      style: TextStyle(color: Colors.white))),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Make sure we have the correct distance value by explicitly
                  // reading from the current list at the current index
                  final currentList = getCurrentDistanceList(_tempSelectedUnit);
                  final currentValue = currentList[_currentDistanceIndex];

                  widget.onConfirmPressed(currentValue, _tempSelectedUnit);
                  Navigator.pop(context);
                },
                child: Text("Confirm"),
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 45, right: 40, top: 0, bottom: 20),
            child: Text(
                "\'Use Default\' automatically increases search radius until 20 results are found."),
          ),
        ],
      );
    });
  }
}
