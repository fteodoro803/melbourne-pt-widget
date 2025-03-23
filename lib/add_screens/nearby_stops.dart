import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/toggle_buttons_row.dart';

import '../ptv_info_classes/route_direction_info.dart';
import '../ptv_info_classes/route_info.dart' as PTRoute;
import '../time_utils.dart';

// Widget for the Address input section with transport type toggle
class NearbyStopsSheet extends StatefulWidget {
  final ScrollController scrollController;
  final TextEditingController locationController;
  final List<Stop> stops;
  final List<PTRoute.Route> routes;
  final ScreenArguments arguments;
  final Function(String) onTransportTypeChanged;
  final Function(Stop, PTRoute.Route) onStopTapped;

  const NearbyStopsSheet({
    super.key,
    required this.scrollController,
    required this.locationController,
    required this.arguments,
    required this.stops,
    required this.routes,
    required this.onTransportTypeChanged,
    required this.onStopTapped,
  });

  @override
  State<NearbyStopsSheet> createState() => _NearbyStopsSheetState();
}

class _NearbyStopsSheetState extends State<NearbyStopsSheet> {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_pin, size: 16),
                  SizedBox(width: 3),
                  Flexible(
                    child: TextField(
                      controller: widget.locationController,
                      readOnly: true,
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Address",
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              ToggleButtonsRow(
                arguments: widget.arguments,
                onTransportTypeChanged: widget
                    .onTransportTypeChanged, // Pass callback
              ),
              Divider(),

              // CustomListTile(
              //   transport: sampleTransport,  // Pass in your transport data here
              // ),

            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 0.0,
              right: 16.0,
              bottom: 0.0,
              left: 16.0,
            ),
            itemCount: widget.stops.length, // The length of the _stops list
            itemBuilder: (context, index) {
              // Ensure the lists are of equal length
              if (index >= widget.routes.length) {
                return Container(); // Return an empty container if there is no route data
              }

              // Safely access data in stops and routes
              final stopName = widget.stops[index].name;
              final routeNumber = widget.routes[index].number.toString();
              final routeName = widget.routes[index].name;

              return ListTile(
                title: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_pin, size: 16), // Icon for location
                        SizedBox(width: 3), // Space between icon and text
                        Flexible(
                          child: Text(
                            stopName,
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
                            routeNumber,
                            style: TextStyle(
                              fontSize: 20, // Bigger text size
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                onTap: () {
                  // Stop rendering this information
                  widget.arguments.transport.stop = widget.stops[index];
                  widget.arguments.transport.route = widget.routes[index];
                  widget.onStopTapped(widget.stops[index], widget.routes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}