import 'package:flutter/material.dart';

class ToggleButtonsRow extends StatelessWidget {
  final String initialTransportType;
  final Function({int? newDistance, String? newTransportType}) onSearchFiltersChanged;
  final Function(String newTransportType) onTransportTypeChanged;

  const ToggleButtonsRow({
    Key? key,
    required this.initialTransportType,
    required this.onSearchFiltersChanged,
    required this.onTransportTypeChanged
  }) : super(key: key);

  // Helper method to check which button is selected
  bool _isSelected(String transportType) {
    return initialTransportType == transportType;
  }

  // Method to handle button press
  void _handleButtonPress(BuildContext context, String transportType) {
    if (initialTransportType == transportType) {
      // If the same button is pressed again, switch to "all"
      onSearchFiltersChanged(newTransportType: "all", newDistance: null);
      onTransportTypeChanged("all");
    } else {
      // Otherwise select the pressed button
      onSearchFiltersChanged(newTransportType: transportType, newDistance: null);
      onTransportTypeChanged(transportType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // "All transport" button
        ElevatedButton(
          onPressed: () => _handleButtonPress(context, "all"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: _isSelected("all") ?
            Theme.of(context).colorScheme.secondaryContainer :
            Theme.of(context).colorScheme.secondary,
            minimumSize: Size(50, 50),
          ),
          child: Text(
            "All Transport",
            style: TextStyle(color: _isSelected("all") ? Colors.white : Colors.black),
          ),
        ),
        SizedBox(width: 8),

        // Tram button
        ElevatedButton(
          onPressed: () => _handleButtonPress(context, "tram"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: _isSelected("tram") ?
            Theme.of(context).colorScheme.secondaryContainer :
            Theme.of(context).colorScheme.secondary,
            minimumSize: Size(50, 50),
            shape: CircleBorder(),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV tram Logo.png",
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Other buttons follow the same pattern...
        SizedBox(width: 8),

        // Train button
        ElevatedButton(
          onPressed: () => _handleButtonPress(context, "train"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: _isSelected("train") ?
            Theme.of(context).colorScheme.secondaryContainer :
            Theme.of(context).colorScheme.secondary,
            minimumSize: Size(50, 50),
            shape: CircleBorder(),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV train Logo.png",
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 8),

        // Bus button
        ElevatedButton(
          onPressed: () => _handleButtonPress(context, "bus"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: _isSelected("bus") ?
            Theme.of(context).colorScheme.secondaryContainer :
            Theme.of(context).colorScheme.secondary,
            minimumSize: Size(50, 50),
            shape: CircleBorder(),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV bus Logo.png",
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 8),

        // VLine button
        ElevatedButton(
          onPressed: () => _handleButtonPress(context, "vLine"),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: _isSelected("vLine") ?
            Theme.of(context).colorScheme.secondaryContainer :
            Theme.of(context).colorScheme.secondary,
            minimumSize: Size(50, 50),
            shape: CircleBorder(),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV vLine Logo.png",
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}