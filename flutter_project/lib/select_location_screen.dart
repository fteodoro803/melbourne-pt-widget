import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/ptvInfoClasses/LocationInfo.dart';
import 'selections.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key, required this.userSelections});

  // Stores User Selections
  final Selections userSelections;

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  String _screenName = "SelectLocation";
  TextEditingController _locationController = TextEditingController();    // Placeholder until map api is implemented

  // Initialising State
  @override
  void initState() {
    super.initState();

    // Debug Printing
    if (kDebugMode) {
      print("Screen: $_screenName");
    }
  }

  void setLocation() {
    Location newLocation = Location(location: _locationController.text);
    widget.userSelections.location = newLocation;

    // TestPrint
    if (kDebugMode) {
      print(widget.userSelections);
    }
  }

  // Rendering
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Location"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _locationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Latitude,Longitude',
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () {
                setLocation();
                Navigator.pushNamed(context, '/selectStopScreen');
              },
              child: Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}
