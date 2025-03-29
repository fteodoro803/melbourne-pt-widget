import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/toggle_buttons_row.dart';

import '../ptv_info_classes/route_info.dart' as pt_route;
import '../widgets/transport_widgets.dart';

enum ResultsFilter {
  lowFloor(name: "Low Floor"),
  shelter(name: "Shelter");

  final String name;

  const ResultsFilter({required this.name});
}

class NearbyStopsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Function(String) onTransportTypeChanged;
  final Function(Stop, pt_route.Route) onStopTapped;

  const NearbyStopsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
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

    String address = widget.arguments.searchDetails!.locationController.text;

    return Column(
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
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocationWidget(textField: address, textSize: 18),
              SizedBox(height: 8),
              ToggleButtonsRow(
                onTransportTypeChanged: widget.onTransportTypeChanged,
              ),
              SizedBox(height: 4),
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
            itemCount: widget.arguments.searchDetails!.stops.length,
            itemBuilder: (context, index) {

              if (index >= widget.arguments.searchDetails!.routes.length) {
                return Container();
              }

              final route = widget.arguments.searchDetails!.routes[index];
              final stopName = widget.arguments.searchDetails!.stops[index].name;
              final routeName = widget.arguments.searchDetails!.routes[index].name;
              final distance = widget.arguments.searchDetails!.stops[index].distance;
              final routeType = widget.arguments.searchDetails!.routes[index].type.type.name;

              return Card(
                child: ListTile(
                  // Distance in meters from marker
                  trailing: Text("${distance?.round()}m", style: TextStyle(fontSize: 16)),

                  // Stop and route details
                  title: Column(
                    children: [
                      LocationWidget(textField: stopName, textSize: 16),
                      SizedBox(height: 4),
                      RouteWidget(route: route),
                      if (routeType != "train" && routeType != "vLine")
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            routeName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),

                  // Render stop details sheet if stop is tapped
                  onTap: () async {
                    await widget.onStopTapped(widget.arguments.searchDetails!.stops[index], widget.arguments.searchDetails!.routes[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}