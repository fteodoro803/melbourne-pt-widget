import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as PTRoute;
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/toggle_buttons_row.dart'; // Make sure to import your custom widget if it's used here.

class DraggableScrollableSheetWidget extends StatefulWidget {
  final ScrollController scrollController;
  final TextEditingController locationController;
  final List<Stop> stops;
  final List<PTRoute.Route> routes;
  final ScreenArguments arguments;
  final Function(String) onTransportTypeChanged; // Callback for notifying the transport type change

  const DraggableScrollableSheetWidget({
    super.key,
    required this.scrollController,
    required this.locationController,
    required this.stops,
    required this.routes,
    required this.arguments,
    required this.onTransportTypeChanged, // Pass the callback here
  });

  @override
  State<DraggableScrollableSheetWidget> createState() => _DraggableScrollableSheetWidgetState();
}
class _DraggableScrollableSheetWidgetState extends State<DraggableScrollableSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  red: 0,
                  green: 0,
                  blue: 0,
                  alpha: 0.1,
                ),
                spreadRadius: 1,
                blurRadius: 7,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
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
                controller: scrollController,
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
                      onTransportTypeChanged: widget.onTransportTypeChanged, // Pass callback
                    ),
                    Divider(),

                    // CustomListTile(
                    //   transport: sampleTransport,  // Pass in your transport data here
                    // ),

                  ],
                ),
              ),
              Expanded (
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 0.0,
                    right: 16.0,
                    bottom: 0.0,
                    left: 16.0,
                  ),
                  itemCount: widget.stops.length,  // The length of the _stops list
                  itemBuilder: (context, index) {
                    // Ensure the lists are of equal length
                    if (index >= widget.routes.length) {
                      return Container();  // Return an empty container if there is no route data
                    }

                    // Safely access data in stops and routes
                    final stopName = widget.stops[index].name;
                    final routeNumber = widget.routes[index].number.toString();
                    final routeName = widget.routes[index].name;

                    return ListTile(
                      title: Text("$stopName: ($routeNumber)"),
                      subtitle: Text(routeName),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}