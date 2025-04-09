import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'widgets/screen_widgets.dart' as ScreenWidgets;

class FindRoutesScreen extends StatefulWidget {

  FindRoutesScreen({
    super.key,
  });

  @override
  _FindRoutesScreenState createState() => _FindRoutesScreenState();
}

class _FindRoutesScreenState extends State<FindRoutesScreen> {
  Map<String, bool> _transportTypeFilters = {};

  void _handleTransportToggle(String transportType) {
    bool wasSelected = _transportTypeFilters[transportType]!;
    String newTransportToggled;
    if (wasSelected) {
      newTransportToggled = "all";
    }
    else {
      newTransportToggled = transportType;
    }
    setState(() {
      for (var entry in _transportTypeFilters.entries) {
        String type = entry.key;
        if (type == newTransportToggled) {
          _transportTypeFilters[type] = true;
        }
        else {
          _transportTypeFilters[type] = false;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _transportTypeFilters = {
      "all" : true,
      "tram" : false,
      "bus" : false,
      "train" : false,
      "vLine" : false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find Routes"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Divider(),
          SizedBox(height: 8),
          SearchBar(
            controller: TextEditingController(),
            hintText: "Search...",
            leading: Icon(Icons.search),

            constraints: BoxConstraints(maxWidth: 350, minHeight: 50)
          ),
          SizedBox(height: 12),
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: _transportTypeFilters.keys.map((transportType) {
              final isSelected = _transportTypeFilters[transportType] ?? false;
              return ScreenWidgets.TransportToggleButton(
                isSelected: isSelected,
                transportType: transportType,
                handleTransportToggle: _handleTransportToggle,
              );
            }).toList(),
          ),

        ]
      ),
      // bottomNavigationBar: BottomNavigation(
      // currentIndex: 2,
      // updateMainPage: null,
      // ),
    );
  }
}