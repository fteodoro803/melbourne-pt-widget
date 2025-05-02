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
  final dynamic state;
  final List<bool> savedList;
  final Function(List<bool>) handleSave;

  const RouteHeaderWidget({
    super.key,
    required this.showDirection,
    required this.stop,
    required this.route,
    required this.trips,
    required this.disruptions,
    required this.state,
    required this.savedList,
    required this.handleSave
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationWidget(textField: stop.name,
              textSize: 18,
              scrollable: true),

          // Stop location
          ListTile(
            contentPadding: EdgeInsets.all(0),
            visualDensity: VisualDensity(horizontal: -4, vertical: -4),
            dense: true,
            title: Row(
              children: [
                SizedBox(width: 8),

                // Vertical line
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Color(0xFF717171),
                  ),
                ),

                if (showDirection)

                SizedBox(width: 10),
                RouteWidget(route: route, scrollable: false),
              ],
            ),
            trailing: SizedBox(
              width: 63,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    child: Icon(Icons.info, color: Color(
                        0xFF4F82FF), size: 27),
                    onTap: () async {
                      await showModalBottomSheet(
                          constraints: BoxConstraints(maxHeight: 500),
                          context: context,
                          builder: (BuildContext context) {
                            return TripInfoSheet(
                              route: route,
                              stop: stop,
                              disruptions: disruptions,
                              state: state,
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
            ),
          ),

          Divider(),
        ],
      ),
    );
  }
}