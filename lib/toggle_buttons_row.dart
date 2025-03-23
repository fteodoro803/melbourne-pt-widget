import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/screen_arguments.dart';

class ToggleButtonsRow extends StatefulWidget {

  // Constructor
  const ToggleButtonsRow({super.key, required this.arguments, required this.onTransportTypeChanged});

  final ScreenArguments arguments;
  final Function(String) onTransportTypeChanged; // Callback for parent widget

  @override
  _ToggleButtonsRowState createState() => _ToggleButtonsRowState();
}

class _ToggleButtonsRowState extends State<ToggleButtonsRow> {
  // Track the selected state of each button
  bool isAllSelected = false;
  bool isTramSelected = false;
  bool isTrainSelected = false;
  bool isBusSelected = false;
  bool isVLineSelected = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // Align buttons to the start of the row
      children: [
        // "All" button
        ElevatedButton(
          onPressed: () {
            setState(() {
              print("All selected");
              isAllSelected = !isAllSelected; // Toggle state
              if (isAllSelected) {
                isTramSelected = false;
                isBusSelected = false;
                isVLineSelected = false;
                isTrainSelected = false;
              }
            });
            widget.arguments.transportType = "all";
            widget.onTransportTypeChanged("all");
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: isAllSelected ? Colors.grey : Color(0xFFD6D6D6), // Remove internal padding
            minimumSize: Size(50, 50),
          ),
          child: Text(
            "All Transport",
            style: TextStyle(color: isAllSelected ? Colors.black : Colors.black),
          ),
        ),
        SizedBox(width: 8), // Space between buttons
        // Tram button
        ElevatedButton(
          onPressed: () {
            setState(() {
              print("Tram selected");
              isTramSelected = !isTramSelected; // Toggle state
              if (isTramSelected) {
                isAllSelected = false;
                isBusSelected = false;
                isVLineSelected = false;
                isTrainSelected = false;
              }
            });
            widget.arguments.transportType = "1";
            widget.onTransportTypeChanged("1");
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, backgroundColor: isTramSelected ? Colors.grey : Color(0xFFD6D6D6), // Remove internal padding
            minimumSize: Size(50, 50), // Set the size of the button
            shape: CircleBorder(), // Change color when selected
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV Tram Logo.png",
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 8),
        // Train button
        ElevatedButton(
          onPressed: () {
            setState(() {
              print("Train selected");
              isTrainSelected = !isTrainSelected; // Toggle state
              if (isTrainSelected) {
                isTramSelected = false;
                isBusSelected = false;
                isVLineSelected = false;
                isAllSelected = false;
              }
            });
            widget.arguments.transportType = "0";
            widget.onTransportTypeChanged("0");
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, backgroundColor: isTrainSelected ? Colors.grey : Color(0xFFD6D6D6),
            minimumSize: Size(50, 50),
            shape: CircleBorder(),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV Train Logo.png",
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 8),
        // Bus button
        ElevatedButton(
          onPressed: () {
            setState(() {
              print("Bus selected");
              isBusSelected = !isBusSelected; // Toggle state
              if (isBusSelected) {
                isTramSelected = false;
                isTrainSelected = false;
                isVLineSelected = false;
                isAllSelected = false;
              }
            });
            widget.arguments.transportType = "2";
            widget.onTransportTypeChanged("2");
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, backgroundColor: isBusSelected ? Colors.grey : Color(0xFFD6D6D6),
            minimumSize: Size(50, 50),
            shape: CircleBorder(),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV Bus Logo.png",
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(width: 8),
        // VLine button
        ElevatedButton(
          onPressed: () {
            setState(() {
              print("VLine selected");
              isVLineSelected = !isVLineSelected; // Toggle state
              if (isVLineSelected) {
                isTramSelected = false;
                isTrainSelected = false;
                isBusSelected = false;
                isAllSelected = false;
              }
            });
            widget.arguments.transportType = "3";
            widget.onTransportTypeChanged("3");
            widget.arguments.transport.routeType = "3" as RouteType?;
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, backgroundColor: isVLineSelected ? Colors.grey : Color(0xFFD6D6D6),
            minimumSize: Size(50, 50),
            shape: CircleBorder(),
          ),
          child: ClipOval(
            child: Image.asset(
              "assets/icons/PTV VLine Logo.png",
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