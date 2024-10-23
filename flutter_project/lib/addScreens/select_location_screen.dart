import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/ptvInfoClasses/location_info.dart';
import '../transport.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key, required this.transport});

  // Stores User Selections
  final Transport transport;

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

    // Normalize the location input by removing spaces
    newLocation.location = newLocation.location.replaceAll(' ', '');

    widget.transport.location = newLocation;

    // TestPrint
    if (kDebugMode) {
      print(widget.transport);
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
