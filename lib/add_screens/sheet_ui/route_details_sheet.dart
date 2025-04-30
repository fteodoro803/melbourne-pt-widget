import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/trip_widgets.dart';
import 'package:get/get.dart';
import '../../domain/route.dart' as pt_route;
import '../../domain/stop.dart';
import '../controllers/search_controller.dart' as search_controller;
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../utility/search_utils.dart';
import '../widgets/sticky_header_delegate.dart';

class RouteDetailsSheet extends StatefulWidget {
  final ScrollController scrollController;
  final pt_route.Route route;

  const RouteDetailsSheet({
    super.key,
    required this.route,
    required this.scrollController,
  });

  @override
  _RouteDetailsSheetState createState() => _RouteDetailsSheetState();
}

class _RouteDetailsSheetState extends State<RouteDetailsSheet> {
  SearchUtils searchUtils = SearchUtils();

  late String _direction;
  bool _isDirectionReversed = false;
  List<SuburbStops> _suburbStops = [];

  @override
  void initState() {
    super.initState();

    if (widget.route.directions != null && widget.route.directions!.isNotEmpty) {
      _direction = widget.route.directions![0].name;
    }

    _getSuburbStops();
  }

  Future<void> _getSuburbStops() async {
    List<Stop> stopsAlongRoute = widget.route.stopsAlongRoute!;
    List<SuburbStops> newSuburbStops = await searchUtils.getSuburbStops(stopsAlongRoute, widget.route);

    setState(() {
      _suburbStops = newSuburbStops;
    });
  }

  void _changeDirection() {
    if (widget.route.directions != null && widget.route.directions!.length > 1) {
      for (var suburb in _suburbStops) {
        suburb.stops = suburb.stops.reversed.toList();
      }

      setState(() {
        _isDirectionReversed = !_isDirectionReversed;
        _suburbStops = _suburbStops.reversed.toList();
        _direction = _direction == widget.route.directions![0].name
            ? widget.route.directions![1].name
            : widget.route.directions![0].name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;

    if (_suburbStops.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        // Pinned route + direction header
        SliverPersistentHeader(
          pinned: true,
          delegate: StickyHeaderDelegate(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: EdgeInsets.fromLTRB(12, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RouteWidget(route: route, scrollable: false),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    title: AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0.2, 0), end: Offset(0, 0),
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          "To: $_direction",
                          key: ValueKey(_direction),
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    trailing: AnimatedRotation(
                      turns: _isDirectionReversed ? 0.5 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Icon(Icons.compare_arrows),
                    ),
                    onTap: () {
                      _changeDirection();
                    },
                  ),

                ],
              ),
            ),
            height: 95,
          ),
        ),

        // Suburb sticky headers + stops
        ..._suburbStops.map((suburb) {
          return SliverStickyHeader(
            header: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                suburb.suburb,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                  final stop = suburb.stops[index];
                  return Column(
                    children: [
                      ListTile(
                        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                        title: Text(stop.name, style: TextStyle(fontSize: 15)),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () async {
                          Get.find<search_controller.SearchController>().setRoute(route);
                          Get.find<search_controller.SearchController>().pushStop(stop);
                        },
                      ),
                      if (index < suburb.stops.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.7,
                          indent: 16,
                          endIndent: 16,
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                        ),
                    ],
                  );
                },
                childCount: suburb.stops.length,
              ),
            ),

          );
        }),
      ],
    );
  }
}
