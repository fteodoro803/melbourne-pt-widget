import 'package:flutter/material.dart';

class ToggleButtonsRow extends StatefulWidget {
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
              isAllSelected = !isAllSelected; // Toggle state
              if (isAllSelected) {
                isTramSelected = false;
                isBusSelected = false;
                isVLineSelected = false;
                isTrainSelected = false;
              }
            });
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
              isTramSelected = !isTramSelected; // Toggle state
              if (isTramSelected) {
                isAllSelected = false;
                isBusSelected = false;
                isVLineSelected = false;
                isTrainSelected = false;
              }
            });
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
              isTrainSelected = !isTrainSelected; // Toggle state
              if (isTrainSelected) {
                isTramSelected = false;
                isBusSelected = false;
                isVLineSelected = false;
                isAllSelected = false;
              }
            });
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
              isBusSelected = !isBusSelected; // Toggle state
              if (isBusSelected) {
                isTramSelected = false;
                isTrainSelected = false;
                isVLineSelected = false;
                isAllSelected = false;
              }
            });
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
              isVLineSelected = !isVLineSelected; // Toggle state
              if (isVLineSelected) {
                isTramSelected = false;
                isTrainSelected = false;
                isBusSelected = false;
                isAllSelected = false;
              }
            });
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