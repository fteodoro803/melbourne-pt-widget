import 'package:flutter/material.dart';

class DistanceFilterSheet extends StatefulWidget {
  final String selectedDistance;
  final String selectedUnit;
  final Function(String, String) onConfirmPressed;

  const DistanceFilterSheet({
    super.key,
    required this.selectedDistance,
    required this.selectedUnit,
    required this.onConfirmPressed
  });

  @override
  _DistanceFilterSheetState createState() => _DistanceFilterSheetState();
}

class _DistanceFilterSheetState extends State<DistanceFilterSheet> {
  late FixedExtentScrollController _distanceScrollController;
  late FixedExtentScrollController _unitScrollController;

  final String _initialSelectedMeters = "300";
  final String _initialSelectedKilometers = "5";
  final String _initialSelectedUnit = "m";

  List<String> meterList = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"];
  List<String> kilometerList = ["1", "2", "3", "4", "5", "10"];
  List<String> distanceUnitsList = ["m", "km"];

  late String _tempSelectedDistance;
  late String _tempSelectedUnit;

  @override
  void initState() {
    super.initState();

    _tempSelectedDistance = widget.selectedDistance;
    _tempSelectedUnit = widget.selectedUnit;

    // Use the correct list based on the selected unit
    List<String> currentDistanceList = _tempSelectedUnit == "m" ? meterList : kilometerList;

    // Initialize controllers with correct positions
    int distanceIndex = currentDistanceList.indexOf(_tempSelectedDistance);
    if (distanceIndex == -1) distanceIndex = 0;

    _distanceScrollController = FixedExtentScrollController(initialItem: distanceIndex);
    _unitScrollController = FixedExtentScrollController(initialItem: distanceUnitsList.indexOf(_tempSelectedUnit));
  }

  @override
  void dispose() {
    _distanceScrollController.dispose();
    _unitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        // Update the temp selected distance when it changes
                        // Using the correct list based on current unit
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
                      setModalState(() {
                        String newUnit = distanceUnitsList[index];
                        if (newUnit != _tempSelectedUnit) {
                          // Store old values
                          String oldUnit = _tempSelectedUnit;

                          // Update unit first
                          _tempSelectedUnit = newUnit;

                          // Set default values for the new unit
                          if (newUnit == "m") {
                            _tempSelectedDistance = _initialSelectedMeters;
                          } else {
                            _tempSelectedDistance = _initialSelectedKilometers;
                          }

                          // Get the new list based on the selected unit
                          final newList = _tempSelectedUnit == "m" ? meterList : kilometerList;

                          // Find the index in the new list
                          int newIndex = newList.indexOf(_tempSelectedDistance);
                          if (newIndex == -1) newIndex = 0;

                          // Force update the scroll controller to the new position
                          _distanceScrollController.jumpToItem(newIndex);
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

                      // Update controllers to show default values
                      _unitScrollController.jumpToItem(distanceUnitsList.indexOf(_initialSelectedUnit));
                      _distanceScrollController.jumpToItem(meterList.indexOf(_initialSelectedMeters));
                    });

                    widget.onConfirmPressed(_initialSelectedMeters, _initialSelectedUnit);
                    Navigator.pop(context);
                  },
                  child: Text("Use Default", style: TextStyle(color: Colors.white))
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirmPressed(_tempSelectedDistance, _tempSelectedUnit);
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
}