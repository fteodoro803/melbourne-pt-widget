import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/dev/location.dart';
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

  // String? _style;
  // // Loads Google Map Style from JSON
  // Future<String?> _loadMapStyle() async {
  //   try {
  //     String loadString = await rootBundle.loadString('assets/mapStyles/darkModeStyle.json');
  //     return loadString;
  //   } catch (e) {
  //     return null;
  //   }
  // }
  //
  // void _setStyle() async {
  //   _style = await _loadMapStyle();
  // }

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

    // Loading in Style
    // _setStyle();
    setState(() {});
  }

  void setLocation() {
    Location newLocation = Location(coordinates: _locationController.text);

    // Normalize the location input by removing spaces
    newLocation.coordinates = newLocation.coordinates.replaceAll(' ', '');

    widget.arguments.testLocation = newLocation;
  }

  void setMapLocation() {
    String? latitude = currentPosition?.latitude.toString();
    String? longitude = currentPosition?.longitude.toString();
    String? location = "$latitude,$longitude";

    Location newLocation = Location(coordinates: location);
    widget.arguments.testLocation = newLocation;
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
              // style: _style,      // Dark mode/Light mode
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

        // Manual Location (~test)
        Positioned(
          left: 20,
          right: 20,
          bottom: 80,
          child: SizedBox(
            width: 300,
            child: TextField(
              controller: _locationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Latitude,Longitude',
              ),
            ),
          ),
        ),

        // Button
        Positioned(
          bottom: 20,
          left: 100,
          right: 100,
          child: ElevatedButton(
              onPressed: () {
                _locationController.text.isNotEmpty
                    ? setLocation()
                    : setMapLocation(); // ~test, for when manual location is on

                // setMapLocation();
                Navigator.pushNamed(context, '/selectStopScreen',
                    arguments: widget.arguments);
              },
              child: Text("Confirm")),
        )
      ]),
    );
  }
}
