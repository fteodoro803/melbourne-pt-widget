import 'dart:async';

import 'package:flutter/material.dart';

import '../../file_service.dart';
import '../../domain/departure.dart';
import '../../screen_arguments.dart';
import '../.deprecated/search_details.dart';
import '../.deprecated/departure_card.dart';
import '../../trip.dart';
import '../widgets/transport_widgets.dart';

class TransportDetailsSheet extends StatefulWidget {
  final ScreenArguments arguments;
  final SearchDetails searchDetails;
  final ScrollController scrollController;
  final Function(Departure, Transport) onDepartureTapped;

  const TransportDetailsSheet({
    super.key,
    required this.arguments,
    required this.searchDetails,
    required this.scrollController,
    required this.onDepartureTapped
  });

  @override
  _TransportDetailsSheetState createState() => _TransportDetailsSheetState();
}

class _TransportDetailsSheetState extends State<TransportDetailsSheet> {
  late bool _isSaved = false;
  late Transport transport;
  Map<String, bool> filters = {};

  ScrollController listController = ScrollController();

  @override
  void initState() {
    super.initState();
    transport = widget.searchDetails.transport!;
    filters = {
      "Air Conditioning": false,
      "Low Floor": false,
    };
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
  Future<void> _handleSave() async {
    setState(() {
      _isSaved = !_isSaved;
    });
    if (_isSaved) {
      await append(transport);  // Add transport to saved list
      widget.arguments.callback();
    } else {
      await deleteMatchingTransport(transport);  // Remove transport from saved list
      widget.arguments.callback();
    }
  }

  @override
  Widget build(BuildContext context) {

    List<Departure>? filteredDepartures = widget.searchDetails.transport!.departures;
    if (filters['Low Floor'] == true) {
      filteredDepartures = filteredDepartures?.where((departure) => departure.hasLowFloor == filters['Low Floor']).toList();
    }

    listController.addListener(() {
      if (listController.offset <= 0) {
        widget.scrollController.jumpTo(0);
      }
    });

    return CustomScrollView(
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
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text("Towards ${transport.direction!.name}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.4
                                        )
                                      )
                                    ),

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
                                              onTap: () {
                                              },
                                            ),
                                            SizedBox(width: 6),
                                            GestureDetector(
                                              child: Icon(Icons.warning_outlined, color: Color(
                                                  0xFFF6833C)),
                                              onTap: () {
                                              },
                                            ),
                                            SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () {
                                                _handleSave();
                                                SaveTransportService.renderSnackBar(context, _isSaved);
                                              },
                                              child: FavoriteButton(isSaved: _isSaved),
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
                  children: filters.entries.map((MapEntry<String,bool> filter) {
                    return FilterChip(
                      label: Text(filter.key),
                      selected: filter.value,
                      onSelected: (bool selected) {
                        setState(() {
                          filters[filter.key] = !filters[filter.key]!;
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

        // Departures list section
        SliverFillRemaining(
          hasScrollBody: true,
          fillOverscroll: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              shrinkWrap: true,
              controller: listController,
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(0.0),
              itemCount: filteredDepartures!.length > 30 ? 30 : filteredDepartures.length,
              itemBuilder: (context, index) {
                final departure = filteredDepartures?[index];
                return DepartureCard(transport: widget.searchDetails.transport!, departure: departure!, onDepartureTapped: widget.onDepartureTapped);
              },
            ),
          ),
        ),
      ],
    );
  }
}

