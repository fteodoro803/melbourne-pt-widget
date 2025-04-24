import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/trip_widgets.dart';

import '../../domain/direction.dart';
import '../../domain/route.dart' as pt_route;
import '../../domain/stop.dart';
import '../../ptv_service.dart';
import '../.deprecated/search_details.dart';
import '../utility/search_utils.dart';

class RouteDetailsSheet extends StatefulWidget {
  final SearchDetails searchDetails;
  final ScrollController scrollController;
  final Function(Stop, pt_route.Route, bool) onStopTapped;

  const RouteDetailsSheet({
    super.key,
    required this.searchDetails,
    required this.scrollController,
    required this.onStopTapped
  });

  @override
  State<RouteDetailsSheet> createState() => _RouteDetailsSheetState();
}

class _RouteDetailsSheetState extends State<RouteDetailsSheet> {
  late pt_route.Route _route;
  List<SuburbStops>? _suburbStops;
  String? _direction;
  late List<RouteDirection> _directions;
  PtvService ptvService = PtvService();
  SearchUtils searchUtils = SearchUtils();

  Future<void> getSuburbStops() async {
    List<Stop> stopsAlongRoute = _route.stopsAlongRoute!;
    List<SuburbStops> suburbStops = await searchUtils.getSuburbStops(stopsAlongRoute, _route);
    setState(() {
      _suburbStops = suburbStops;
    });
  }

  void _changeDirection() {
    setState(() {
      for (var suburb in _suburbStops!) {
        suburb.stops = suburb.stops.reversed.toList();
      }
      _suburbStops = _suburbStops?.reversed.toList();
      _direction = _direction == _directions[0].name ? _directions[1].name : _directions[0].name;
    });
  }

  @override
  void initState() {
    super.initState();
    _route = widget.searchDetails.route!;
    _directions = _route.directions!;
    if (_directions.isNotEmpty) {
      _direction = _directions[0].name;
    }

    getSuburbStops();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.searchDetails.route;

    if (_suburbStops == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
        padding: EdgeInsets.all(16),
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        children: [
          RouteWidget(route: route!, scrollable: false,),
          SizedBox(height: 4),
          ListTile(
              title: Text("To: $_direction", style: TextStyle(fontSize: 18)),
              trailing: GestureDetector(
                  child: Icon(Icons.compare_arrows),
                  onTap: () {
                    _changeDirection();
                  }
              )
          ),
          // Text(_route.name, style: TextStyle(fontSize: 18)),
          Divider(),

          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            margin: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: _suburbStops!.map((suburb) {
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                            trailing: GestureDetector(
                              child: !suburb.isExpanded
                                  ? Icon(Icons.keyboard_arrow_down_sharp, size: 30)
                                  : Icon(Icons.keyboard_arrow_up_sharp, size: 30),
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
                              onTap: () async {
                                await widget.onStopTapped(stop, widget.searchDetails.route!, false);
                              }
                          );
                        }),
                    ]
                );
              }).toList(),
            ),
          ),
        ]
    );
  }
}