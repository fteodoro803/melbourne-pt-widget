import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/disruption.dart';
import '../../domain/stop.dart';
import '../../domain/route.dart' as pt_route;
import '../../ptv_service.dart';
import '../controllers/navigation_service.dart';
import '../utility/search_utils.dart';
import '../utility/time_utils.dart';
import '../utility/trip_utils.dart';
import '../widgets/trip_info_widgets.dart';


class TripInfoSheet extends StatefulWidget {
  final pt_route.Route route;
  final Stop stop;
  final List<Disruption> disruptions;

  const TripInfoSheet({
    super.key,
    required this.route,
    required this.stop,
    required this.disruptions
  });

  @override
  TripInfoSheetState createState() => TripInfoSheetState();
}

class TripInfoSheetState extends State<TripInfoSheet> {
  final NavigationService navigationService = Get.find<NavigationService>();

  List<Stop> nearbyStops = [];
  List<Disruption> plannedDisruptions = [];
  List<Disruption> currentDisruptions = [];
  SearchUtils searchUtils = SearchUtils();
  PtvService ptvService = PtvService();

  @override
  void initState() {
    super.initState();


    for (var disruption in widget.disruptions) {
      if (disruption.status == 'Planned') {
        plannedDisruptions.add(disruption);
      } else if (disruption.status == 'Current') {
        currentDisruptions.add(disruption);
      }
    }

    getConnections();
  }

  Future<void> getConnections() async {
    LatLng stopLocation = LatLng(widget.stop.latitude!, widget.stop.longitude!);
    List<Stop> uniqueStops = await searchUtils.getUniqueStops(stopLocation, "all", 200);
    setState(() {
      nearbyStops = uniqueStops;
    });
  }

  @override
  Widget build(BuildContext context) {
    String disruptionsString = "Disruptions";
    if (widget.disruptions.isNotEmpty) {
      disruptionsString = "Disruptions (${widget.disruptions.length})";
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.black.withValues(alpha: 0)),
                onPressed: null,
              ),
              Text(
                "Stop and Route Information",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // or Get.back() if you're using GetX navigation
                },
              ),
            ],
          ),
        ),
        Divider(height: 4),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Information"),
                    Tab(text: disruptionsString),
                    Tab(text: "Connections")
                  ]
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        children: [
                          Card(
                            margin: const EdgeInsets.all(0),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                              dense: true,
                              leading: Text("Ticketing: ", style: TextStyle(fontSize: 16)),
                              title: Text("Zone 1")),
                          ),
                          Divider(height: 1),
                          Card(
                            margin: const EdgeInsets.all(0),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                              dense: true,
                              leading: Text("High Platform: ", style: TextStyle(fontSize: 16)),
                              title: Text("No")),
                          ),
                          Divider(height: 1),
                          Card(
                            margin: const EdgeInsets.all(0),
                            elevation: 1,
                            child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                dense: true,
                                leading: Text("Shelter: ", style: TextStyle(fontSize: 16)),
                                title: Text("No")),
                          ),
                          Divider(height: 1),
                          Card(
                            margin: const EdgeInsets.all(0),
                            elevation: 1,
                            child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                dense: true,
                                leading: Text("Ticket Booth: ", style: TextStyle(fontSize: 16)),
                                title: Text("No")),
                          ),
                          Divider(height: 1),

                        ]
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            Row(
                              children: [
                                Text("Status: ", style: TextStyle(fontSize: 16)),
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 4),
                                Text(widget.route.status, style: TextStyle(fontSize: 16)),
                              ],
                            ),

                            Divider(),
                            Text("Current Disruptions", style: TextStyle(fontSize: 18)),
                            _buildDisruptions(currentDisruptions, true),
                            Divider(),
                            Text("Planned Disruptions", style: TextStyle(fontSize: 18)),
                            _buildDisruptions(plannedDisruptions, false),

                          ]
                        )
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0),
                        child: ListView.builder(
                          physics: ClampingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: nearbyStops.length,
                          itemBuilder: (context, index) {
                            final stop = nearbyStops[index];
                            return _buildNearbyStopCard(stop);
                          },
                        ),
                      ),

                    ]
                  )
                )
              ],
            )
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyStopCard(Stop stop) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                RouteTypeImage(routeType: stop.routeType!.name, size: 25),
                SizedBox(width: 8),
                Expanded(
                  child: LocationWidget(
                    textField: stop.name,
                    textSize: 14,
                    scrollable: true,
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.directions_walk, size: 18),
                    Text("${stop.distance?.round()} m", style: TextStyle(fontSize: 14)),
                  ],
                )
              ],
            ),
            Divider(),
            if (stop.routes != null && stop.routes!.isNotEmpty)
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: stop.routes!.length,
                itemBuilder: (context, index) {
                  final route = stop.routes![index];
                  final routeLabel = TripUtils.getLabel(route, route.type.name);
                  final routeName = TripUtils.getName(route, route.type.name);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    trailing: Icon(Icons.keyboard_arrow_right_outlined),
                    leading: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: route.colour != null
                            ? ColourUtils.hexToColour(route.colour!)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 280),
                        child: Text(
                          routeLabel ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: route.textColour != null
                                ? ColourUtils.hexToColour(route.textColour!)
                                : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    title: routeName != null
                        ? Text(routeName, style: TextStyle(fontSize: 14, height: 1.1))
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await navigationService.navigateToStop(stop, route);
                    }
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisruptions(List<Disruption> disruptions, bool isCurrent) {
    if (disruptions.isEmpty) {
      if (isCurrent) {
        return Text("There are no current disruptions.");
      } else {
        return Text("There are no planned disruptions.");
      }
    }
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: disruptions.length,
      itemBuilder: (context, index) {
        final disruption = disruptions[index];
        final startDate = disruption.fromDate;
        final endDate = disruption.toDate;
        String startDateString = "Unknown";
        String endDateString = "Until further notice";
        if (startDate != null) {
          startDateString = TimeUtils.fullDateString(startDate);
        }
        if (endDate != null) {
          endDateString = TimeUtils.fullDateString(endDate);
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(disruption.type),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(disruption.description),
              Text("Start: $startDateString"),
              Text("End: $endDateString"),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: SizedBox(
                  height: 30,
                  width: 95,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Read more "),
                      Icon(Icons.output, size: 16)
                    ],
                  ),
                ),
                onPressed: () => launchUrl(Uri.parse(disruption.url)),
              )
            ],
          ),
        );
      },
    );
  }
}