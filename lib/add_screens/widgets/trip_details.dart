import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/stop.dart';
import '../../domain/route.dart' as pt_route;
import '../controllers/search_controller.dart' as search_controller;
import '../utility/search_utils.dart';
import '../utility/trip_utils.dart';
import 'get_widgets.dart';


class TripDetails extends StatefulWidget {
  final pt_route.Route route;
  final Stop stop;

  const TripDetails({
    super.key,
    required this.route,
    required this.stop
  });

  @override
  TripDetailsState createState() => TripDetailsState();
}

class TripDetailsState extends State<TripDetails> {
  List<Stop> nearbyStops = [];
  SearchUtils searchUtils = SearchUtils();

  @override
  void initState() {
    super.initState();
    expandConnections();
  }

  Future<void> expandConnections() async {
    LatLng stopLocation = LatLng(widget.stop.latitude!, widget.stop.longitude!);
    List<Stop> uniqueStops = await searchUtils.getStops(stopLocation, "all", 200);
    setState(() {
      nearbyStops = uniqueStops;
    });
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
                Image.asset(
                  "assets/icons/PTV ${stop.routeType?.name ?? 'default'} Logo.png",
                  width: 25,
                  height: 25,
                ),
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
                      await Get.find<search_controller.SearchController>().setRoute(route);
                      await Get.find<search_controller.SearchController>().pushStop(stop);
                      Navigator.pop(context);
                    }
                  );
                },
              ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Information"),
              Tab(text: "Disruptions"),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Status: ", style: TextStyle(fontSize: 16)),
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 4),
                          Text(widget.route.status, style: TextStyle(fontSize: 16)),
                        ],
                      ),

                      Text("There are currently no disruptions."),
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
    );
  }
}