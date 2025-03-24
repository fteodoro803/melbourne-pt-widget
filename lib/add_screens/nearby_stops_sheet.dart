import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/toggle_buttons_row.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../ptv_info_classes/route_info.dart' as PTRoute;

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

  double calculateDistance(LatLng from, LatLng to) {
    // Using geolocator to calculate the distance in meters
    double distanceInMeters = Geolocator.distanceBetween(
      from.latitude, from.longitude,
      to.latitude, to.longitude,
    );

    return distanceInMeters;
  }

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
              // Draggable Scrollable Sheet Handle
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

              // Address and toggleable transport type buttons
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
                            controller: widget.arguments.searchDetails.locationController,
                            readOnly: true,
                            style: TextStyle(fontSize: 18),
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

              // List of stops
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

                    final stopName = widget.arguments.searchDetails.stops[index].name;
                    final routeNumber = widget.arguments.searchDetails.routes[index].number.toString();
                    final routeName = widget.arguments.searchDetails.routes[index].name;
                    // final distanceInMeters = calculateDistance(widget.arguments.searchDetails.markerPosition!,
                    //     LatLng(widget.arguments.searchDetails.stop?.latitude as double,
                    //         widget.arguments.searchDetails.stop?.longitude as double));

                    return Card(
                      child: ListTile(
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
                                    widget.arguments.searchDetails.transportType == "Train" ||
                                        widget.arguments.searchDetails.transportType == "VLine"
                                        ? ""
                                        : routeNumber,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                      
                              ],
                            ),
                            Text(
                              "$routeName",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                      
                            // Text("${distanceInMeters}m")
                          ],
                        ),

                        onTap: () {
                          // Render stop details sheet if stop is tapped
                          widget.onStopTapped(widget.arguments.searchDetails.stops[index], widget.arguments.searchDetails.routes[index]);
                        },
                      ),
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