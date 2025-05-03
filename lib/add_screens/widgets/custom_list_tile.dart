import 'package:flutter/material.dart';
import 'package:flutter_project/domain/trip.dart';
import '../utility/trip_utils.dart';
import 'trip_info_widgets.dart';

import '../utility/time_utils.dart';

class CustomListTile extends StatelessWidget {
  final Trip transport;
  final VoidCallback onTap;
  final bool? dismissible;
  final VoidCallback? onDismiss;

  // Constructor
  const CustomListTile({
    super.key,
    required this.transport,
    this.onTap = _emptyFunction,
    this.dismissible,
    this.onDismiss,
  }) : assert(dismissible == false || dismissible == null
      || (dismissible == true && onDismiss != null),
      "onDismiss must be provided if dismissible is true");

  // Empty function for default OnTap
  static void _emptyFunction() {}

  // Alert for deleting this stop

  @override
  Widget build(BuildContext context) {
    final Trip transport = this.transport;

    final departure = transport.departures != null
        && transport.departures!.isNotEmpty
        ? transport.departures![0] : null;
    DateTime? estimated;
    DepartureStatus? status;
    String? minutesString;
    if (departure != null) {
      estimated = departure.estimatedDepartureUTC
        ?? departure.scheduledDepartureUTC;
      status = TimeUtils.getDepartureStatus(
        departure.scheduledDepartureUTC,
        departure.estimatedDepartureUTC,
      );

      minutesString =
          TimeUtils.minutesString(estimated, departure.scheduledDepartureUTC!);
    }

  // Enables the Widget to be Deleted/Dismissed by Swiping
  return Dismissible(
    key: Key(transport.toString()),
    direction: dismissible == true
        ? DismissDirection.endToStart
        : DismissDirection.none,    // Dismissible if true
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 30),
      child: Icon(Icons.delete),
    ),
    onDismissed: (_) {
      onDismiss!();
    },

    // Information Tile
    child: Stack(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 12, right: 30, top: 4, bottom: 0),
          title: Column(
            spacing: 2,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LocationWidget above the vertical line
              LocationWidget(
                  textField: transport.stop!.name,
                  textSize: 16,
                  scrollable: false),
              SizedBox(height: 2),
              Row(children: [
                Expanded(
                  child: NewRouteWidget(
                    route: transport.route!,
                    direction: transport.direction,
                    scrollable: false,),
                ),
              ]),


              if (transport.departures != null)
                ListTile(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.access_time_filled),
                  title: DeparturesStringWidget(departures: transport.departures),
                  trailing: departure != null
                      && status!.hasDeparted == false
                      && status.isWithinAnHour == true
                      ? Container(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                          color: ColourUtils.hexToColour(status.getColorString),
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: Text(
                        minutesString!,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 15
                        ),
                      ))
                      : null,
                ),
            ],
          ),
          onTap: onTap,
        ),
        Positioned(
          right: -4,
          top: 32,
          child: PopupMenuButton<String>(
            onSelected: (String choice) {
              if (choice == 'Remove from Favourites') {
                onDismiss!();
              }
            },
            icon: const Icon(Icons.more_vert, size: 30),
            color: Theme.of(context).colorScheme.secondaryContainer,
            itemBuilder: (BuildContext context) {
              return {'Remove from Favourites'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice, style: TextStyle(fontSize: 16)),
                );
              }).toList();
            },
          ),
        ),
      ]),
    );
  }
}

