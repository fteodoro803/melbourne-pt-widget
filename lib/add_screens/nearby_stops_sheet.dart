import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/toggle_buttons_row.dart';

import '../ptv_info_classes/route_info.dart' as PTRoute;

// Widget for the Address input section with transport type toggle
class NearbyStopsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final Function(String) onTransportTypeChanged;
  final Function(Stop, PTRoute.Route) onStopTapped;

  const NearbyStopsSheet({
    super.key,
    required this.arguments,
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
          controller: ScrollController(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_pin, size: 16),
                  SizedBox(width: 3),
                  Flexible(
                    child: TextField(
                      controller: widget.arguments.searchDetails.locationController,
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
                onTransportTypeChanged: widget
                    .onTransportTypeChanged,
              ),
              Divider(),
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
            itemCount: widget.arguments.searchDetails.stops.length,
            itemBuilder: (context, index) {

              if (index >= widget.arguments.searchDetails.routes.length) {
                return Container();
              }

              // Safely access data in stops and routes
              final stopName = widget.arguments.searchDetails.stops[index].name;
              final routeNumber = widget.arguments.searchDetails.routes[index].number.toString();

              return ListTile(
                title: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_pin, size: 16),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            stopName,
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
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
                              fontSize: 20,
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
                  widget.onStopTapped(widget.arguments.searchDetails.stops[index], widget.arguments.searchDetails.routes[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}