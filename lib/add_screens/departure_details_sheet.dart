import 'dart:async';

import 'package:flutter/material.dart';

import '../ptv_info_classes/departure_info.dart';
import '../screen_arguments.dart';
import '../transport.dart';
import '../widgets/transport_widgets.dart';

class DepartureDetailsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Departure departure;

  DepartureDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.departure,
  });

  @override
  _DepartureDetailsSheetState createState() => _DepartureDetailsSheetState();
}

class _DepartureDetailsSheetState extends State<DepartureDetailsSheet> {
  late Transport transport;

  @override
  void initState() {
    super.initState();
    transport = widget.arguments.transport;
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // DraggableScrollableSheet Handle
        HandleWidget(),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          controller: widget.scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Route and stop details
                  Expanded(
                    child: Column(
                      children: [
                        LocationWidget(textField: transport.stop!.name, textSize: 16),
                        SizedBox(height: 4),
                        RouteWidget(route: transport.route!, direction: transport.direction),
                        SizedBox(height: 4),
                        Text("Scheduled: ${widget.departure.scheduledDepartureTime}"),
                        SizedBox(height: 4),
                        Text("Estimated: ${widget.departure.estimatedDepartureTime ?? 'N/A'}"),
                      ],
                    ),
                  ),
                ],

              ),
              SizedBox(height: 4),
              Divider(),
              SizedBox(height: 10),

            ],
          ),
        ),


      ],
    );
  }
}

