import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';
import '../../file_service.dart';
import '../../ptv_info_classes/departure_info.dart';
import '../../transport.dart';
import '../widgets/departure_card.dart';
import '../widgets/save_transport_sheet.dart';
import '../widgets/screen_widgets.dart';
import '../widgets/transport_widgets.dart';

class StopDetailsSheet extends StatefulWidget {

  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Function(Transport) onTransportTapped;
  final Function(Departure, Transport) onDepartureTapped;

  const StopDetailsSheet({
    super.key,
    required this.arguments,
    required this.scrollController,
    required this.onTransportTapped,
    required this.onDepartureTapped
  });

  @override
  State<StopDetailsSheet> createState() => _StopDetailsSheetState();
}

class _StopDetailsSheetState extends State<StopDetailsSheet> {
  late List<Transport> _transports;

  List<bool> _savedList = [];

  // Function to initialize the savedList
  Future<void> initializeSavedList() async {
    List<bool> tempSavedList = [];

    for (var transport in widget.arguments.searchDetails!.directions) {
      // Check if the transport is already saved
      bool isSaved = await isTransportSaved(transport);
      tempSavedList.add(isSaved);
    }

    setState(() {
      _savedList = tempSavedList;
    });
  }

  @override
  void initState() {
    super.initState();
    _transports = widget.arguments.searchDetails!.directions;
    initializeSavedList();
  }

  Future<void> _onConfirmPressed(List<bool> tempSavedList) async {
    for (var transport in _transports) {
      int index = _transports.indexOf(transport);
      bool wasSaved = _savedList[index];
      bool isNowSaved = tempSavedList[index];
      if (wasSaved != isNowSaved) {
        if (!wasSaved) {
          await append(transport);
          widget.arguments.callback();
        }
        else {
          await deleteMatchingTransport(transport);
          widget.arguments.callback();
        }
      }
    }
    setState(() {
      _savedList = tempSavedList;
    });
  }

  @override
  Widget build(BuildContext context) {

    // List<Transport> transportsList = widget.arguments.searchDetails!.directions.where((t) => t.departures != null && t.departures!.isNotEmpty).toList();
    List<Transport> transportsList = widget.arguments.searchDetails!.directions;


    if (_savedList.isEmpty) {
      return CircularProgressIndicator();
    }

    return Column(
      children: [
        // Draggable Scrollable Sheet Handle
        if (!widget.arguments.searchDetails!.isSheetExpanded)
          HandleWidget(),

        // Stop and route details
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            controller: widget.scrollController,
            physics: ClampingScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationWidget(textField: widget.arguments.searchDetails!.stop!.name, textSize: 18, scrollable: true),

                    // Stop location
                    ListTile(
                      contentPadding: EdgeInsets.all(0),
                      visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                      dense: true,
                      title: Row(
                        children: [
                          SizedBox(width: 8),
                          Container(
                            width: 4,

                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Color(0xFF717171),
                            ),
                          ),
                          SizedBox(width: 10),
                          RouteWidget(route: widget.arguments.searchDetails!.route!, scrollable: false,),
                        ],
                      ),
                      trailing: GestureDetector(
                        child: FavoriteButton(isSaved: _savedList.contains(true)),
                        onTap: () async {
                          await showModalBottomSheet(
                            constraints: BoxConstraints(maxHeight: 320),
                            context: context,
                            builder: (BuildContext context) {
                              return SaveTransportSheet(
                                searchDetails: widget.arguments.searchDetails!,
                                savedList: _savedList,
                                onConfirmPressed: _onConfirmPressed,
                              );
                            }
                          );
                        },
                      ),
                    ),
                    Divider(),

                    // Departures for each direction
                    Column(
                      children: transportsList.map((transport) {
                        var departures = transport.departures;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                                dense: true,
                                contentPadding: EdgeInsets.all(0),
                                title: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    "Towards ${transport.direction?.name}",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 100,
                                  child: GestureDetector(
                                    child: Row(
                                      children: [
                                        SizedBox(width: 18),
                                        Text("See all", style: TextStyle(fontSize: 16,)),
                                        Icon(Icons.keyboard_arrow_right),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        widget.onTransportTapped(transport);
                                      });
                                    }
                                  ),
                                ),
                              ),

                              // Display departures if they exist
                              if (departures != null && departures.isNotEmpty)

                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(0.0),
                                  itemCount: departures.length > 2 ? 2 : departures.length,
                                  itemBuilder: (context, index) {
                                    final departure = departures[index];
                                    return DepartureCard(transport: transport, departure: departure, onDepartureTapped: widget.onDepartureTapped);
                                  },
                                ),

                              // Display a message if no departures
                              if (departures == null || departures.isEmpty)
                                Card(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  elevation: 1,
                                  child: Text("No departures to show."),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}