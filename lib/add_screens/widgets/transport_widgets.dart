import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/departure_info.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;
import 'package:flutter_project/ptv_info_classes/stop_info.dart';
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
    String routeLabel = TransportUtils.getLabel(route, routeType);
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
  final RouteDirection? direction;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    String routeType = route.type.name;
    String routeLabel = TransportUtils.getLabel(route, routeType);

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
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required bool isSaved,
  }) : _isSaved = isSaved;

  final bool _isSaved;

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: 30,
      height: 30,
      child: Center(
        child: Icon(
          _isSaved ? Icons.star : Icons.star_border,
          size: 30,
          color: _isSaved ? Colors.yellow : null,
        ),
      ),
    );
  }
}

class SaveTransportService {
  static void renderSnackBar(BuildContext context, bool isSaved) {
    floatingSnackBar(
      message: isSaved ? 'Added to Saved Transports.' : 'Removed from Saved Transports.',
      context: context,
      textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      duration: const Duration(milliseconds: 2000),
      backgroundColor: isSaved ? Color(0xFF4E754F) : Color(0xFF7C291F),
    );
  }
}

class MinutesUntilDepartureWidget extends StatelessWidget {
  const MinutesUntilDepartureWidget({
    super.key,
    required this.departure,
  });

  final Departure departure;

  @override
  Widget build(BuildContext context) {

    DepartureStatus departureStatus;

    String? minutesUntilNextDepartureText;

    // Gets the first departure information
    departureStatus = TransportUtils.getDepartureStatus(
      departure.estimatedDepartureTime,
      departure.scheduledDepartureTime,
    );
    String? departureTime = departure.estimatedDepartureTime ?? departure.scheduledDepartureTime;

    minutesUntilNextDepartureText = TimeUtils.minutesToString(TimeUtils.timeDifference(departureTime!));

    // Check if minutesUntilNextDepartureText is null after calculation
    if (minutesUntilNextDepartureText == null) {
      return SizedBox.shrink(); // Return an empty widget if minutesUntilNextDepartureText is null
    }

    return Text(
        minutesUntilNextDepartureText,
        style: TextStyle(
        fontSize: 16, // Smaller font size for "Now"
        fontWeight: FontWeight.w600,
        color: ColourUtils.getColorForStatus(departureStatus.status),
      height: 1.1,
      ),
    );

    //   Column(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     if (minutesUntilNextDepartureText == "Now")
    //       Text(
    //         minutesUntilNextDepartureText!,
    //         style: TextStyle(
    //           fontSize: 16, // Smaller font size for "Now"
    //           fontWeight: FontWeight.w600,
    //           color: TransportUtils.getColorForStatus(departureStatus.status),
    //           height: 1.1,
    //         ),
    //       )
    //     else ...[
    //       Text(
    //         minutesUntilNextDepartureText!.split(' ').first,
    //         style: TextStyle(
    //           fontSize: 20, // Larger font size for the first word
    //           fontWeight: FontWeight.w600,
    //           color: TransportUtils.getColorForStatus(departureStatus.status),
    //           height: 1.1,
    //         ),
    //       ),
    //       Text(
    //         minutesUntilNextDepartureText.split(' ').skip(1).join(' '),
    //         style: TextStyle(
    //           fontSize: 14, // Smaller font size for the remaining text
    //           fontWeight: FontWeight.w600,
    //           color: TransportUtils.getColorForStatus(departureStatus.status),
    //           height: 1.1,
    //         ),
    //       ),
    //     ],
    //   ],
    // );
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
                bool hasLowFloor = departures![index].hasLowFloor ?? false;
                String departureTime = departures![index].estimatedDepartureTime ??
                    departures![index].scheduledDepartureTime ??
                    "No Data";

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
                      TimeUtils.trimTime(departureTime),
                      style: TextStyle(
                        fontSize: 16,
                        // fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasLowFloor) ...[
                      SizedBox(width: 3),
                      Image.asset(
                        "assets/icons/Low Floor Icon.png",
                        width: 14,
                        height: 14,
                      ),
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
  final Function(Stop stop, pt_route.Route route) onStopTapped;
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
            onTap: () async {
              await onStopTapped(stop, route);
            },
          );
        }
    );
  }
}