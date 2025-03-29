import 'dart:async';

import 'package:flutter/material.dart';

import '../file_service.dart';
import '../screen_arguments.dart';
import '../widgets/departures_list.dart';
import '../transport.dart';
import '../widgets/transport_widgets.dart';

enum ResultsFilter {
  airConditioning(name: "Air Conditioning"),
  lowFloor(name: "Low Floor");

  final String name;

  const ResultsFilter({required this.name});
}

class TransportDetailsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final ScrollController scrollController;

  TransportDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
  });

  @override
  _TransportDetailsSheetState createState() => _TransportDetailsSheetState();
}

class _TransportDetailsSheetState extends State<TransportDetailsSheet> {
  late bool _isSaved = false;
  late Transport transport;

  Set<ResultsFilter> filters = <ResultsFilter>{};

  @override
  void initState() {
    super.initState();
    transport = widget.arguments.transport;
    checkSaved();
  }

  // Function to check if transport is saved
  Future<void> checkSaved() async {
    bool isSaved = await isTransportSaved(transport);

    setState(() {
      _isSaved = isSaved; // Set the state with the updated list
    });
  }

  // Function to save or delete transport
  Future<void> handleSave(bool isSaved) async {
    if (isSaved) {
      await append(transport);  // Add transport to saved list
      widget.arguments.callback();
    } else {
      await deleteMatchingTransport(transport);  // Remove transport from saved list
      widget.arguments.callback();
    }
  }

  bool get lowFloorFilter => filters.contains(ResultsFilter.lowFloor);
  bool get airConditionerFilter => filters.contains(ResultsFilter.airConditioning);

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
                      ],
                    ),
                  ),

                  // Add to favorites button
                  GestureDetector(
                    child: FavoriteButton(isSaved: _isSaved),
                    onTap: ()  {
                      setState(() {
                        _isSaved = !_isSaved;
                      });

                      handleSave(_isSaved);
                      SaveTransportService.renderSnackBar(context, _isSaved);
                    },
                  ),
                ],

              ),
              SizedBox(height: 4),
              Divider(),

              // Search filters
              Wrap(
                spacing: 5.0,
                children: ResultsFilter.values.map((ResultsFilter result) {
                  return FilterChip(
                      label: Text(result.name),
                      selected: filters.contains(result),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            filters.add(result);
                          } else {
                            filters.remove(result);
                          }
                        });
                      }
                  );
                }).toList(),
              ),
              SizedBox(height: 10),

              Text(
                "Upcoming Departures",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),

        // List of departures
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DeparturesList(departuresLength: 30, transport: transport, lowFloorFilter: lowFloorFilter, airConditionerFilter: airConditionerFilter,),
          ),
        ),
      ],
    );
  }
}

