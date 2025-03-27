import 'package:flutter/material.dart';

class ToggleButtonsRow extends StatefulWidget {

  final Function(String) onTransportTypeChanged; // Callback for parent widget
  const ToggleButtonsRow({super.key, required this.onTransportTypeChanged});

  @override
  _ToggleButtonsRowState createState() => _ToggleButtonsRowState();
}

class _ToggleButtonsRowState extends State<ToggleButtonsRow> {
  // Track the selected state of each button
  bool isAllSelected = true;
  bool isTramSelected = false;
  bool isTrainSelected = false;
  bool isBusSelected = false;
  bool isVLineSelected = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // "All transport" button
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
                widget.onTransportTypeChanged("all");
              }
            });
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: isAllSelected || (!isTramSelected && !isBusSelected && !isVLineSelected && !isTrainSelected) ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.secondary,
            minimumSize: Size(50, 50),
          ),
          child: Text(
            "All Transport",
            style: TextStyle(color: isAllSelected || (!isTramSelected && !isBusSelected && !isVLineSelected && !isTrainSelected) ? Colors.white : Colors.black),
          ),
        ),
        SizedBox(width: 8),

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
                widget.onTransportTypeChanged("tram");
              }
              else {
                isAllSelected = true;
                widget.onTransportTypeChanged("all");
              }
            });

          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: isTramSelected ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.secondary,
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
        SizedBox(width: 8),

        // Train button
        ElevatedButton(
          onPressed: () {
            setState(() {
              print("Train selected");
              isTrainSelected = !isTrainSelected;
              if (isTrainSelected) {
                isTramSelected = false;
                isBusSelected = false;
                isVLineSelected = false;
                isAllSelected = false;
                widget.onTransportTypeChanged("train");
              }
              else {
                isAllSelected = true;
                widget.onTransportTypeChanged("all");
              }
            });
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: isTrainSelected ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.secondary,
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
          onPressed: () {
            setState(() {
              print("Bus selected");
              isBusSelected = !isBusSelected; // Toggle state
              if (isBusSelected) {
                isTramSelected = false;
                isTrainSelected = false;
                isVLineSelected = false;
                isAllSelected = false;
                widget.onTransportTypeChanged("bus");
              }
              else {
                isAllSelected = true;
                widget.onTransportTypeChanged("all");
              }
            });
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: isBusSelected ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.secondary,
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
          onPressed: () {
            setState(() {
              print("VLine selected");
              isVLineSelected = !isVLineSelected; // Toggle state
              if (isVLineSelected) {
                isTramSelected = false;
                isTrainSelected = false;
                isBusSelected = false;
                isAllSelected = false;
                widget.onTransportTypeChanged("vLine");
              }
              else {
                isAllSelected = true;
                widget.onTransportTypeChanged("all");
              }
            });
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: isVLineSelected ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.secondary,
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