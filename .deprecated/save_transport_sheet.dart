import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'search_details.dart';
import '../widgets/transport_widgets.dart';

import 'package:flutter_project/domain/route_info.dart' as pt_route;
import 'package:flutter_project/trip.dart';

class SaveTransportSheet extends StatefulWidget {
  final SearchDetails searchDetails;
  final List<bool> savedList;
  final Function(List<bool>) onConfirmPressed;

  const SaveTransportSheet({
    super.key,
    required this.searchDetails,
    required this.savedList,
    required this.onConfirmPressed
  });

  @override
  _SaveTransportSheetState createState() => _SaveTransportSheetState();
}

class _SaveTransportSheetState extends State<SaveTransportSheet> {
  List<bool> tempSavedList = [];
  bool hasListChanged = false;
  late pt_route.Route route;
  late String stopName;
  late List<Transport> transportList;

  @override
  void initState() {
    super.initState();
    route = widget.searchDetails.route!;
    stopName = widget.searchDetails.stop!.name;
    transportList = widget.searchDetails.transportList!;
    tempSavedList = List.from(widget.savedList);
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: () async {
                  if (hasListChanged) {
                    await widget.onConfirmPressed(tempSavedList);
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
              title: LocationWidget(textField: stopName, textSize: 18, scrollable: false),
              subtitle: RouteWidget(route: route, scrollable: false,),
            ),
          ),
          SizedBox(height: 12),
          Text("Choose direction:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Column(
            children: transportList.map((transport) {
              var index = transportList.indexOf(transport);
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
                      hasListChanged = !(listEquals(widget.savedList, tempSavedList));
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