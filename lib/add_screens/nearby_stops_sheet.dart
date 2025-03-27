import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/toggle_buttons_row.dart';

import '../ptv_info_classes/route_info.dart' as PTRoute;
import '../time_utils.dart';

enum ResultsFilter {
  lowFloor(name: "Low Floor"),
  shelter(name: "Shelter");

  final String name;

  const ResultsFilter({required this.name});
}

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

  Set<ResultsFilter> filters = <ResultsFilter>{};

  bool get lowFloorFilter => filters.contains(ResultsFilter.lowFloor);
  bool get shelterFilter => filters.contains(ResultsFilter.shelter);

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
                    Wrap(
                      spacing: 5.0,
                      children: ResultsFilter.values.map((ResultsFilter result) {
                        return FilterChip(
                            label: Text(result.name),
                            selected: filters.contains(result),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  filters.add(result);
                                } else {
                                  filters.remove(result);
                                }
                              });
                            }
                        );
                      }).toList(),
                    ),
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
                    final distance = widget.arguments.searchDetails.stops[index].distance;
                    final routeColour = widget.arguments.searchDetails.routes[index].colour;
                    final routeTextColour = widget.arguments.searchDetails.routes[index].textColour;
                    final routeType = widget.arguments.searchDetails.routes[index].type.type.name;

                    return Card(
                      child: ListTile(
                        trailing: Text("${distance?.round()}m", style: TextStyle(fontSize: 16)),
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
                                  // "assets/icons/PTV tram Logo.png",
                                  "assets/icons/PTV ${routeType} Logo.png",
                                  width: 40,
                                  height: 40,
                                ),
                                SizedBox(width: 8),
                      
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      // color: Colors.grey,
                                      color: ColourUtils.hexToColour(routeColour!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.arguments.searchDetails.transportType == "train" ||
                                          widget.arguments.searchDetails.transportType == "vLine"
                                          ? ""
                                          : routeNumber,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        // color: Colors.white,
                                        color: ColourUtils.hexToColour(routeTextColour!),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                      
                              ],
                            ),
                            Text(
                              routeName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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