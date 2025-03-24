import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';

import '../departures_list.dart';

// Widget for the Address input section with transport type toggle
class StopDetailsSheet extends StatefulWidget {

  final ScreenArguments arguments;

  const StopDetailsSheet({
    super.key,
    required this.arguments,
  });

  @override
  State<StopDetailsSheet> createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<StopDetailsSheet> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          controller: ScrollController(),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.location_pin, size: 16), // Icon for location
                  SizedBox(width: 3), // Space between icon and text
                  Flexible(
                    child: Text(
                      widget.arguments.searchDetails.stop!.name,
                      style: TextStyle(fontSize: 16), // Adjust stopName font size
                      overflow: TextOverflow.ellipsis,  // Apply ellipsis if text overflows
                      maxLines: 1,  // Limit to 1 line
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4), // Space between lines
              Row(
                children: [
                  Image.asset(
                    "assets/icons/PTV Tram Logo.png",
                    width: 40,
                    height: 40,
                  ),
                  SizedBox(width: 8),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.arguments.searchDetails.route!.number,
                      style: TextStyle(
                        fontSize: 20, // Bigger text size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Towards ${widget.arguments.searchDetails.directions[0].route?.direction}"),
            DeparturesList(departuresLength: 2, transport: widget.arguments.searchDetails.directions[0]),
            Text("Towards ${widget.arguments.searchDetails.directions[1].route?.direction}"),
            DeparturesList(departuresLength: 2, transport: widget.arguments.searchDetails.directions[0]),
          ]
        )
      ],
    );
  }
}