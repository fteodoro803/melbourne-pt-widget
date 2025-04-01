import 'package:flutter/material.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/widgets/transport_widgets.dart';

class CustomListTile extends StatelessWidget {
  final Transport transport;
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
  }) : assert(dismissible == false || dismissible == null || (dismissible == true && onDismiss != null), "onDismiss must be provided if dismissible is true");

  // Empty function for default OnTap
  static void _emptyFunction() {}

  // Alert for deleting this stop

  @override
  Widget build(BuildContext context) {
    final Transport transport = this.transport;

  // Enables the Widget to be Deleted/Dismissed by Swiping
  return Dismissible(
    key: Key(transport.toString()),
    direction: dismissible == true? DismissDirection.endToStart : DismissDirection.none,    // Dismissible if true
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
    child: ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LocationWidget above the vertical line
          LocationWidget(textField: transport.stop!.name, textSize: 16, scrollable: false),

          // Row for the vertical line and the rest of the widgets
          Row(
            children: [
              SizedBox(width: 4),
              // Vertical line
              Container(
                width: 2,
                color: Colors.grey,
                height: 70,
              ),
              SizedBox(width: 10), // Optional space between the line and the widgets
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(0),
                      title: RouteWidget(route: transport.route!, direction: transport.direction, scrollable: false,),
                      trailing: MinutesUntilDepartureWidget(departure: transport.departures![0]),
                    ),
                    DeparturesStringWidget(departures: transport.departures),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    ),
  );  }
}

