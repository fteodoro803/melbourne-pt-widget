import 'package:flutter/material.dart';
import 'package:flutter_project/domain/departure.dart';
import 'package:flutter_project/domain/direction.dart';
import 'package:flutter_project/domain/route.dart' as pt_route;
import '../utility/trip_utils.dart';
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

class RouteLabelContainer extends StatelessWidget {
  const RouteLabelContainer({
    super.key,
    required this.route,
  });

  final pt_route.Route route;

  @override
  Widget build(BuildContext context) {
    String routeType = route.type.name;
    String routeLabel = TripUtils.getLabel(route, routeType) ?? 'Unknown';
    Color routeColour = ColourUtils.hexToColour(route.colour!);
    Color routeTextColour = ColourUtils.hexToColour(route.textColour!);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: route.colour != null
            ? routeColour
            : Colors.grey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        routeLabel,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: route.textColour != null
              ? routeTextColour
              : Colors.black,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class RouteWidget extends StatelessWidget {
  const RouteWidget({
    super.key,
    required this.route,
    this.direction,
    required this.scrollable,
  });

  final pt_route.Route route;
  final Direction? direction;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    String routeType = route.type.name;
    String routeLabel = TripUtils.getLabel(route, routeType) ?? 'Unknown';

    return Row(
      children: [
        Image.asset(
          "assets/icons/PTV $routeType Logo.png",
          width: 30,
          height: 30,
        ),
        SizedBox(width: 8),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: route.colour != null
                ? ColourUtils.hexToColour(route.colour!)
                : Colors.grey,
            borderRadius: BorderRadius.circular(8),
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
        SizedBox(width: 10),

        if (routeType != "train" && routeType != "vLine" && direction != null)
          scrollable ?
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                direction?.name ?? "No Data",
                style: TextStyle(
                  fontSize: 18,
                ),

              ),
            )
          )
          : Flexible(
            child: Text(
              direction?.name ?? "No Data",
              style: TextStyle(
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}

class DeparturesStringWidget extends StatelessWidget {
  const DeparturesStringWidget({
    super.key,
    this.departures,
  });

  final List<Departure>? departures;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (departures == null || departures!.isEmpty)
          Text(
            "No times to show.",
            style: TextStyle(height: 1.1),
          )
        else
          ...List.generate(
              departures!.length > 2 ? 2 : departures!.length,
                  (index) {
                final departure = departures![index];
                final bool hasLowFloor = departure.hasLowFloor ?? false;
                final DateTime? estimatedTime = departure.estimatedDepartureUTC ??
                    departure.scheduledDepartureUTC;
                final String timeString = TimeUtils.trimTime(estimatedTime!, false); // todo: if more than a day away, show month!

                return Row(
                  children: [
                    if (index == 0)
                      Text(
                        "At ",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 16,
                        // fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasLowFloor) ...[
                      SizedBox(width: 3),
                      Icon(Icons.accessible, size: 18)
                    ],
                    SizedBox(width: 4),
                    if (index < ((departures!.length > 2 ? 2 : departures!.length) - 1)) ...[
                      Text(
                        // "•",
                        "and",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 4),
                    ],
                  ],
                );
              }
          ),
      ],
    );
  }
}