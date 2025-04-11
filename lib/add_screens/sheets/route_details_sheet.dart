import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/screen_widgets.dart';
import 'package:flutter_project/add_screens/widgets/transport_widgets.dart';

import '../../ptv_info_classes/route_direction_info.dart';
import '../../ptv_info_classes/route_info.dart' as pt_route;
import '../../ptv_info_classes/stop_info.dart';
import '../../ptv_service.dart';
import '../../screen_arguments.dart';
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

    return Column(
      children: [
        HandleWidget(),
        Expanded(
            child: ListView(
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
            )
        ),
      ],
    );
  }
}