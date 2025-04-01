import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:flutter/material.dart';
import '../ptv_info_classes/departure_info.dart';
import '../ptv_info_classes/route_direction_info.dart' as pt_route;
import '../ptv_info_classes/route_info.dart' as pt_route;
import '../time_utils.dart';

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
        Icon(Icons.location_pin, size: textSize),
        SizedBox(width: 3),
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

class RouteWidget extends StatelessWidget {
  const RouteWidget({
    super.key,
    required this.route,
    this.direction,
    required this.scrollable,
  });

  final pt_route.Route route;
  final pt_route.RouteDirection? direction;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    String routeType = route.type.type.name;
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
            routeType == "train" ||
                routeType == "vLine"
                ? route.name
                : route.number,
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

class HandleWidget extends StatelessWidget {
  const HandleWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        height: 5,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
        color: TransportUtils.getColorForStatus(departureStatus.status),
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
                        style: TextStyle(height: 1.1),
                      ),
                    Text(
                      departureTime,
                      style: TextStyle(height: 1.1),
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
                        style: TextStyle(height: 1.1),
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