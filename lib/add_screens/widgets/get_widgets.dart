import 'package:flutter/material.dart';

import '../../domain/route_info.dart' as pt_route;
import '../../domain/stop_info.dart';
import '../utility/time_utils.dart';

class LocationWidget extends StatelessWidget {
  const LocationWidget({
    super.key,
    required this.textField,
    required this.textSize,
    required this.scrollable,
  });

  final String textField;
  final double textSize;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {

    var textLine = Text(
      textField,
      style: TextStyle(fontSize: textSize),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    return Row(
      children: [
        Icon(Icons.location_pin, size: textSize + 2),
        SizedBox(width: 4),
        scrollable ?
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: textLine,
          ),
        )
            : Flexible(
          child: textLine,
        ),
      ],
    );
  }
}

class ExpandedStopWidget extends StatelessWidget {
  const ExpandedStopWidget({
    super.key,
    required this.stopName,
    required this.distance,
  });

  final String stopName;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.location_pin, size: 20),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                stopName,
                style: TextStyle(fontSize: 17, height: 1.1, fontWeight: FontWeight.w700),

              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.directions_walk, size: 20),
            SizedBox(width: 4),
            Text("${distance?.round()}m", style: TextStyle(fontSize: 17)),
          ],
        )
      ],);
  }
}

class UnexpandedStopWidget extends StatelessWidget {
  const UnexpandedStopWidget({
    super.key,
    required this.stopName,
    required this.routes,
    required this.routeType,
  });

  final String stopName;
  final List<pt_route.Route> routes;
  final String routeType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LocationWidget(textField: stopName, textSize: 18, scrollable: false),
        Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 6,
              children: routes.map((route) {

                String routeLabel = TransportUtils.getLabel(route, routeType);

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: route.colour != null
                        ? ColourUtils.hexToColour(route.colour!)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    routeLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: route.textColour != null
                          ? ColourUtils.hexToColour(route.textColour!)
                          : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],);
  }
}

class ExpandedStopRoutesWidget extends StatelessWidget {
  const ExpandedStopRoutesWidget({
    super.key,
    required this.routes,
    required this.routeType,
    required this.onStopTapped,
    required this.stop,
  });

  final List<pt_route.Route> routes;
  final String routeType;
  final Function(Stop, pt_route.Route) onStopTapped;
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: routes.length,
        itemBuilder: (context, routeIndex) {

          final route = routes[routeIndex];
          String routeLabel = TransportUtils.getLabel(route, routeType);
          String? routeName = TransportUtils.getName(route, routeType);

          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                constraints: BoxConstraints(
                  maxWidth: 280, // Limit the width to a maximum, or you can adjust the value
                ),
                child: Text(
                  routeLabel,
                  style: TextStyle(
                    fontSize: 16,
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
            title: routeName != null ? Text(routeName) : null,
            onTap: ()  {
              onStopTapped(stop, route);
            },
          );
        }
    );
  }
}