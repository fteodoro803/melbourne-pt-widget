import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/ptv_info_classes/location_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final String _screenName = "SelectLocation";
  final TextEditingController _locationController =
      TextEditingController(); // Placeholder until map api is implemented
  DevTools tools = DevTools();

  // Map
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  final LatLng _initialPosition =
      const LatLng(-37.813812122509205, 144.96358311072478);
  LatLng? currentPosition;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      setMarker(_initialPosition);
    });
  }

  // Adds one marker on the map
  void setMarker(LatLng position) {
    markers.clear();
    MarkerId id = MarkerId(markers.length.toString());
    markers.add(Marker(markerId: id, position: position));
  }

  // Initialising State
  @override
  void initState() {
    super.initState();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  void setLocation() {
    Location newLocation = Location(location: _locationController.text);

    // Normalize the location input by removing spaces
    newLocation.location = newLocation.location.replaceAll(' ', '');

    widget.arguments.transport.location = newLocation;
  }

  void setMapLocation() {
    String? latitude = currentPosition?.latitude.toString();
    String? longitude = currentPosition?.longitude.toString();
    String? location = "$latitude,$longitude";

    Location newLocation = Location(location: location);
    widget.arguments.transport.location = newLocation;
  }

  // Rendering
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Location"),
        centerTitle: true,
      ),
      body: Stack(children: [

        // Google Map
        Positioned.fill(
          child: GoogleMap(
              // Updates the center marker based on camera's position
              onCameraMove: (position) {
                setState(() {
                  currentPosition = position.target;
                  setMarker(position.target);
                });
              },
              onMapCreated: _onMapCreated,
              initialCameraPosition:
                  CameraPosition(target: _initialPosition, zoom: 15),
              markers: markers),
        ),

        // Button
        Positioned(
          bottom: 20,
          left: 100,
          right: 100,
          child: ElevatedButton(
              onPressed: () {
                setMapLocation();
                Navigator.pushNamed(context, '/selectStopScreen',
                    arguments: widget.arguments);
              },
              child: Text("Confirm")),
        )
      ]),
    );
  }
}
