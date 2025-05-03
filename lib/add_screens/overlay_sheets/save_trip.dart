import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/route.dart' as pt_route;
import '../../domain/stop.dart';
import '../../domain/trip.dart';
import '../widgets/buttons.dart';
import '../widgets/trip_info_widgets.dart';

class SaveTripSheet extends StatelessWidget {
  final pt_route.Route route;
  final Stop stop;
  final List<bool> savedList;
  final List<Trip> tripList;
  final Function(List<bool>) onConfirmPressed;

  const SaveTripSheet({
    super.key,
    required this.route,
    required this.stop,
    required this.tripList,
    required this.savedList,
    required this.onConfirmPressed
  });

  @override
  Widget build(BuildContext context) {

    final stopName = stop.name;
    List<bool> tempSavedList = List.from(savedList);
    bool hasListChanged = false;

    return StatefulBuilder(builder: (context, setModalState) {
      return Column(
        children: [
          ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 10.0, bottom: 10.0),

              // Cancel button
              child: GestureDetector(
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.left,
                ),
                onTap: () {
                  Navigator.pop(context);
                }
              ),
            ),

            // Confirm button
            trailing: GestureDetector(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 10.0, bottom: 10.0),
                child: Text(
                  "Confirm",
                  style: TextStyle(
                    fontSize: 16,
                    color: hasListChanged ? null : Color(
                        0xFF555555),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              onTap: () async {
                if (hasListChanged) {
                  await onConfirmPressed(tempSavedList);
                  Navigator.pop(context);
                }
              }
            ),

            // Modal sheet title
            title: Text(
              "Save Trip",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Stop and route detail card
          Card(
            color: Colors.black,
            margin: const EdgeInsets.symmetric(horizontal: 18.0),
            elevation: 1,
            child: ListTile(
              title: LocationWidget(textField: stopName, textSize: 18, scrollable: false),
              subtitle: RouteWidget(route: route, scrollable: false),
            ),
          ),

          SizedBox(height: 12),
          Text("Choose direction:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),

          // List of trips (and saved status)
          Column(
            children: tripList.map((trip) {
              var index = tripList.indexOf(trip);
              return Card(
                color: Colors.black,
                margin: const EdgeInsets.only(left: 18.0, right: 18.0, bottom: 6),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 20, right: 16),
                  visualDensity: VisualDensity(horizontal: 2, vertical: 0),
                  dense: true,
                  title: Text(
                    "${trip.direction?.name}",
                    style: TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: FavoriteButton(isSaved: tempSavedList[index]),
                  onTap: () {
                    setModalState(() {
                      tempSavedList[index] = !tempSavedList[index];
                      hasListChanged = !(listEquals(savedList, tempSavedList));
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}