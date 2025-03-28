import 'dart:async';

import 'package:flutter/material.dart';

import '../screen_arguments.dart';
import '../widgets/departures_list.dart';
import '../time_utils.dart';
import '../transport.dart';

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
  late Transport transport;
  Timer? _timer;

  Set<ResultsFilter> filters = <ResultsFilter>{};

  @override
  void initState() {
    super.initState();
    transport = widget.arguments.transport;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get lowFloorFilter => filters.contains(ResultsFilter.lowFloor);
  bool get airConditionerFilter => filters.contains(ResultsFilter.airConditioning);

  @override
  Widget build(BuildContext context) {

    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            controller: widget.scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_pin, size: 16),
                    SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        transport.stop?.name ?? "No Data",
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),

                Row(
                  children: [
                    Image.asset(
                      "assets/icons/PTV ${transport.routeType?.type.name} Logo.png",
                      width: 40,
                      height: 40,
                    ),
                    SizedBox(width: 8),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: transport.route?.colour != null
                            ? ColourUtils.hexToColour(transport.route!.colour!)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transport.routeType?.type.name == "train" ||
                            transport.routeType?.type.name == "vLine"
                            ? transport.direction?.name ?? "No Data"
                            : transport.route?.number ?? "No Data",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: transport.route?.textColour != null
                              ? ColourUtils.hexToColour(transport.route!.textColour!)
                              : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),

                    if (transport.routeType?.type.name != "train" && transport.routeType?.type.name != "vLine")
                      Text(
                        transport.direction?.name ?? "No Data",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4),
                Divider(),
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