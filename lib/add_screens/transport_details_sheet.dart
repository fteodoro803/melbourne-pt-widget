import 'dart:async';

import 'package:flutter/material.dart';

import '../file_service.dart';
import '../ptv_info_classes/departure_info.dart';
import '../screen_arguments.dart';
import '../widgets/departures_list.dart';
import '../transport.dart';
import '../widgets/screen_widgets.dart';
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
  final Function(Departure, Transport) onDepartureTapped;

  TransportDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.onDepartureTapped
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
      mainAxisSize: MainAxisSize.min,

      children: [

        // DraggableScrollableSheet Handle
        if (!widget.arguments.searchDetails!.isSheetExpanded)
          HandleWidget(),

        Expanded(
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Route and stop details
                          Flexible(
                            fit: FlexFit.tight,
                            child: Column(
                              children: [
                                LocationWidget(textField: transport.stop!.name, textSize: 18, scrollable: true),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 67,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: Color(0xFF717171),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Align(alignment: Alignment.topLeft, child: Text("Towards ${transport.direction!.name}", style: TextStyle(fontSize: 16, height: 1.4))),
                                          // SizedBox(height: 4),

                                          ListTile(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                            visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                            dense: true,
                                            title: RouteWidget(route: transport.route!, scrollable: true),
                                            trailing: SizedBox(
                                              width: 90,
                                              child: Row(
                                                children: [
                                                  GestureDetector(
                                                    child: Icon(Icons.info, color: Color(
                                                        0xFF4F82FF)),
                                                    onTap: ()  {
                                                    },
                                                  ),
                                                  SizedBox(width: 6),
                                                  GestureDetector(
                                                    child: Icon(Icons.warning_outlined, color: Color(
                                                        0xFFF6833C)),
                                                    onTap: ()  {
                                                    },
                                                  ),
                                                  SizedBox(width: 4),
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
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                      ),
                      // SizedBox(height: 4),
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
              ),
              // Departures list section that will take remaining space
              SliverFillRemaining(
                hasScrollBody: true,
                fillOverscroll: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DeparturesList(
                    departuresLength: 30,
                    transport: transport,
                    lowFloorFilter: lowFloorFilter,
                    airConditionerFilter: airConditionerFilter,
                    scrollable: true,
                    onDepartureTapped: widget.onDepartureTapped,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

