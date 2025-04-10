import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/route_details_screen.dart';
import 'package:flutter_project/add_screens/widgets/screen_widgets.dart';
import 'package:flutter_project/add_screens/widgets/transport_widgets.dart';

import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;
import '../../screen_arguments.dart';

class RouteDetailsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final pt_route.Route route;
  final String direction;
  final List<SuburbStops> suburbStops;
  final ScrollController scrollController;
  final Function changeDirection;
  final Function onStopTapped;

  const RouteDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.route,
    required this.suburbStops,
    required this.direction,
    required this.changeDirection,
    required this.onStopTapped
  });

  @override
  State<RouteDetailsSheet> createState() => _RouteDetailsSheetState();
}

class _RouteDetailsSheetState extends State<RouteDetailsSheet> {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    return Column(
      children: [
        HandleWidget(),
        Expanded(
            child: ListView(
                padding: EdgeInsets.all(16),
                controller: widget.scrollController,
                physics: ClampingScrollPhysics(),
                children: [
                  RouteWidget(route: route, scrollable: false,),
                  SizedBox(height: 4),
                  ListTile(
                      title: Text("To: ${widget.direction}", style: TextStyle(fontSize: 18)),
                      trailing: GestureDetector(
                          child: Icon(Icons.compare_arrows),
                          onTap: () {
                            widget.changeDirection();
                          }
                      )
                  ),
                  // Text(_route.name, style: TextStyle(fontSize: 18)),
                  Divider(),

                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: widget.suburbStops.map((suburb) {
                        return Column(
                            children: [
                              Container(
                                color: Theme.of(context).colorScheme.secondaryContainer, // You can use any color here
                                child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    title: Text(
                                      suburb.suburb,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    trailing: GestureDetector(
                                      child: Icon(Icons.keyboard_arrow_down_sharp, size: 30),
                                      onTap: () {
                                        setState(() {
                                          suburb.isExpanded = !suburb.isExpanded;
                                        });
                                      },
                                    )
                                ),
                              ),
                              if (suburb.isExpanded)
                                ...suburb.stops.map((stop) {
                                  return ListTile(
                                      visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                      dense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                                      title: Text(stop.name, style: TextStyle(fontSize: 15)),
                                      trailing: Icon(Icons.keyboard_arrow_right),
                                      onTap: () {
                                        widget.onStopTapped(stop);
                                      }
                                  );
                                }),
                            ]
                        );
                      }).toList(),
                    ),
                  ),
                ]
            )
        ),
      ],
    );
  }
}