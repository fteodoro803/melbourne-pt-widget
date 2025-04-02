import 'package:floating_snackbar/floating_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:flutter_project/widgets/departures_list.dart';
import '../file_service.dart';
import '../ptv_info_classes/departure_info.dart';
import '../transport.dart';
import '../widgets/transport_widgets.dart';

class StopDetailsSheet extends StatefulWidget {

  final ScreenArguments arguments;
  final ScrollController scrollController;
  final Function(Transport) onTransportTapped;
  final Function(Departure) onDepartureTapped;

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
  late List<Transport> transports;

  List<bool> savedList = [];

  Future<void> handleSave(List<bool> isSavedList, List<bool> newSavedList) async {
    for (var transport in transports) {
      int index = transports.indexOf(transport);
      bool wasSaved = isSavedList[index];
      bool isNowSaved = newSavedList[index];
      if (wasSaved != isNowSaved) {
        if (!wasSaved) {
          await append(transport);  // Add transport to saved list
          widget.arguments.callback();
        }
        else {
          await deleteMatchingTransport(transport);  // Remove transport from saved list
          widget.arguments.callback();
        }
      }
    }
  }

  // Function to initialize the savedList
  Future<void> initializeSavedList() async {
    List<bool> tempSavedList = [];

    for (var transport in widget.arguments.searchDetails!.directions) {
      // Check if the transport is already saved
      bool isSaved = await isTransportSaved(transport);
      tempSavedList.add(isSaved); // Add true if saved, false if not
    }

    setState(() {
      savedList = tempSavedList;
    }); // Set the state with the updated list
  }

  @override
  void initState() {
    super.initState();
    transports = widget.arguments.searchDetails!.directions;
    initializeSavedList();
  }

  @override
  Widget build(BuildContext context) {

    if (savedList.isEmpty) {
      return CircularProgressIndicator();
    }

    return Column(
      children: [
        // Draggable Scrollable Sheet Handle
        HandleWidget(),

        // Stop and route details
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            controller: widget.scrollController,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LocationWidget(textField: widget.arguments.searchDetails!.stop!.name, textSize: 18, scrollable: true),

                    // Stop location
                    ListTile(
                      contentPadding: EdgeInsets.all(0),
                      visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                      dense: true,
                      title: RouteWidget(route: widget.arguments.searchDetails!.route!, scrollable: false,),
                      trailing: GestureDetector(
                        child: FavoriteButton(isSaved: savedList.contains(true)),
                        onTap: () async {
                          await showModalBottomSheet(
                            constraints: BoxConstraints(maxHeight: 320),
                            context: context,
                            builder: (BuildContext context) {
                              List<bool> tempSavedList = List.from(savedList);
                              bool hasListChanged = false;
                              return StatefulBuilder(builder: (context, setModalState) {

                                return Column(
                                  children: [
                                    ListTile(
                                      leading: Padding(
                                        padding: const EdgeInsets.only(left: 10.0, top: 10.0, bottom: 10.0),
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
                                        onTap: () {
                                          if (hasListChanged) {
                                            handleSave(savedList, tempSavedList);
                                            setState(() {
                                              savedList = tempSavedList;
                                            });
                                            Navigator.pop(context);
                                          }
                                        }
                                      ),
                                      title: Text(
                                        "Save Transport",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Card(
                                      color: Colors.black,
                                      margin: const EdgeInsets.symmetric(horizontal: 18.0),
                                      elevation: 1,
                                      child: ListTile(
                                        title: LocationWidget(textField: widget.arguments.searchDetails!.stop!.name, textSize: 18, scrollable: false),
                                        subtitle: RouteWidget(route: widget.arguments.searchDetails!.route!, scrollable: false,),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text("Choose direction:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                                    SizedBox(height: 8),
                                    Column(
                                      children: widget.arguments.searchDetails!.directions.map((transport) {
                                        var index = widget.arguments.searchDetails!.directions.indexOf(transport);
                                        return Card(
                                          color: Colors.black,
                                          margin: const EdgeInsets.only(left: 18.0, right: 18.0, bottom: 6),
                                          elevation: 1,
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.only(left: 20, right: 16),
                                            visualDensity: VisualDensity(horizontal: 2, vertical: 0),
                                            dense: true,
                                            title: Text(
                                              "${transport.direction?.name}",
                                              style: TextStyle(fontSize: 18),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            trailing: FavoriteButton(isSaved: tempSavedList[index]),
                                            onTap: () {
                                              setModalState(() {
                                                tempSavedList[index] = !tempSavedList[index];
                                                hasListChanged = !savedList.every((item) => item == tempSavedList[savedList.indexOf(item)]);
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
                          );
                        },
                      ),
                    ),
                    Divider(),

                    // Departures for each direction
                    Column(
                      children: widget.arguments.searchDetails!.directions.map((transport) {
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
                                DeparturesList(departuresLength: 2, transport: transport, lowFloorFilter: false, airConditionerFilter: false, onDepartureTapped: widget.onDepartureTapped,),

                              // Display a message if no departures
                              if (departures == null || departures.isEmpty)
                                Card(
                                  margin: const EdgeInsets.all(0.0),
                                  elevation: 0,
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