import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/toggle_buttons_row.dart';

import '../departures_list.dart';
import '../ptv_info_classes/route_direction_info.dart';
import '../ptv_info_classes/route_info.dart' as PTRoute;
import '../transport.dart';

// Widget for the Address input section with transport type toggle
class StopDirectionsSheet extends StatefulWidget {
  final ScrollController scrollController;
  final PTRoute.Route route;
  final Stop stop;
  final List<RouteDirection> directions;
  final ScreenArguments arguments;

  const StopDirectionsSheet({
    super.key,
    required this.scrollController,
    required this.route,
    required this.stop,
    required this.directions,
    required this.arguments,
  });

  @override
  State<StopDirectionsSheet> createState() => _StopDirectionsSheetState();
}

class _StopDirectionsSheetState extends State<StopDirectionsSheet> {

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
          controller: widget.scrollController,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.location_pin, size: 16), // Icon for location
                  SizedBox(width: 3), // Space between icon and text
                  Flexible(
                    child: Text(
                      widget.stop.name,
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
                      widget.route.number,
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
          children: [
            Text("Towards ${widget.directions[0].name}"),
            // DeparturesList(scrollController: widget.scrollController, departuresLength: 2, transport: transport),
            Text("Towards ${widget.directions[1].name}"),
            // DeparturesList(scrollController: widget.scrollController, departuresLength: 2, transport: transport),
          ]
        )
      ],
    );
  }
}