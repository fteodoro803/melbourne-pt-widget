import 'package:flutter/material.dart';
import 'package:flutter_project/add_screens/widgets/trip_info_widgets.dart';

import '../../domain/disruption.dart';
import '../../domain/route.dart' as pt;
import '../../domain/stop.dart';
import '../../domain/trip.dart';
import '../overlay_sheets/save_trip.dart';
import '../overlay_sheets/trip_info.dart';
import '../utility/search_utils.dart';
import 'buttons.dart';

class RouteHeaderWidget extends StatelessWidget {
  final bool showDirection;
  final Stop stop;
  final pt.Route route;
  final List<Trip> trips;
  final List<Disruption> disruptions;
  final List<bool> savedList;
  final Function(List<bool>) handleSave;

  const RouteHeaderWidget({
    super.key,
    required this.showDirection,
    required this.stop,
    required this.route,
    required this.trips,
    required this.disruptions,
    required this.savedList,
    required this.handleSave
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth - 36,
            child: LocationWidget(
              textField: stop.name,
              textSize: 17,
              scrollable: true
            ),
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 8),
              Container(
                width: 4,
                height: showDirection ? 61 : 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Color(0xFF717171),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: showDirection
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (disruptions.isNotEmpty)...[
                          GestureDetector(
                            child: Icon(Icons.error, size: 22,
                                color: Color(0xFFFF8D66)),
                            onTap: () async {
                              await showModalBottomSheet(
                                  constraints: const BoxConstraints(maxHeight: 500),
                                  context: context,
                                  builder: (BuildContext context) {
                                    return TripInfoSheet(
                                      route: route,
                                      stop: stop,
                                      disruptions: disruptions,
                                    );
                                  }
                              );
                            },
                          ),
                          SizedBox(width: 2),
                        ],
                        // Expanded to ensure text doesn't overflow
                        Expanded(
                          child: Text(
                            "To ${trips[0].direction!.name}",
                            style: TextStyle(
                                fontSize: 16,
                                height: 1.4
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),
                    // Improved RouteAndButtonsRow
                    RouteAndButtonsRow(
                        route: route,
                        stop: stop,
                        disruptions: disruptions,
                        savedList: savedList,
                        trips: trips,
                        handleSave: handleSave
                    ),
                  ],
                )
                  : Column(
                    children: [
                      SizedBox(height: 6),
                      RouteAndButtonsRow(
                        route: route,
                        stop: stop,
                        disruptions: disruptions,
                        savedList: savedList,
                        trips: trips,
                        handleSave: handleSave
                      ),
                    ],
                  ),
              ),
            ]
          ),
          SizedBox(height: 2),
          Divider(),
        ],
      ),
    );
  }
}

class RouteAndButtonsRow extends StatelessWidget {
  const RouteAndButtonsRow({
    super.key,
    required this.route,
    required this.stop,
    required this.disruptions,
    required this.savedList,
    required this.trips,
    required this.handleSave,
  });

  final pt.Route route;
  final Stop stop;
  final List<Disruption> disruptions;
  final List<bool> savedList;
  final List<Trip> trips;
  final Function(List<bool> p1) handleSave;

  @override
  Widget build(BuildContext context) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RouteTypeImage(routeType: route.type.name, size: 26),
        SizedBox(width: 8),
        Flexible(child: RouteLabelContainer(route: route, textSize: 15)),
        Spacer(),
        Spacer(),
        Spacer(),
        Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min, // Take only needed space

          children: [
            GestureDetector(
              child: Icon(Icons.info, color: Color(0xFF4F82FF), size: 27),
              onTap: () async {
                await showModalBottomSheet(
                    constraints: BoxConstraints(maxHeight: 500),
                    context: context,
                    builder: (BuildContext context) {
                      return TripInfoSheet(
                        route: route,
                        stop: stop,
                        disruptions: disruptions,
                      );
                    }
                );
              },
            ),
            SizedBox(width: 4),
            GestureDetector(
              child: FavoriteButton(isSaved: savedList.contains(true)),
              onTap: () async {
                if (trips.length > 1) {
                  await showModalBottomSheet(
                      constraints: BoxConstraints(maxHeight: 320),
                      context: context,
                      builder: (BuildContext context) {
                        return SaveTripSheet(
                          savedList: savedList,
                          route: route,
                          stop: stop,
                          tripList: trips,
                          onConfirmPressed: handleSave,
                        );
                      }
                  );
                } else {
                  handleSave([!savedList[0]]);
                  SearchUtils.renderSnackBar(context, !savedList[0]);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}