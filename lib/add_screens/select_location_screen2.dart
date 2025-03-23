import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/ptv_info_classes/location_info.dart';
import 'package:flutter_project/screen_arguments.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_project/toggle_buttons_row.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class SelectLocationScreen2 extends StatefulWidget {
  const SelectLocationScreen2({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<SelectLocationScreen2> createState() => _SelectLocationScreen2State();
}

class _SelectLocationScreen2State extends State<SelectLocationScreen2> {
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
  }

  // Adds a marker at the specified position
  Future<void> setMarker(LatLng position) async {
    MarkerId id = MarkerId(position.toString());  // Unique ID based on position
    markers.clear();
    markers.add(Marker(markerId: id, position: position));

    // Get the address for the dropped marker
    String address = await getAddressFromCoordinates(position.latitude, position.longitude);

    // Update the state with the new address
    setState(() {
      _locationController.text = address; // Set the address in the text field
    });
  }

  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        // Return a string with the address (you can adjust what part of the address you want)
        return "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Address not found"; // Return a default message if something goes wrong
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
      body: Stack(children: [
        // Google Map
        Positioned.fill(
          child: GoogleMap(
            onCameraMove: (position) {
              setState(() {
                currentPosition = position.target;
              });
            },
            onMapCreated: _onMapCreated,
            onLongPress: (LatLng position) {
              setState(() {
                setMarker(position); // Drop marker on long press
              });
            },
            initialCameraPosition: CameraPosition(
                target: _initialPosition, zoom: 15), // No initial marker
            markers: markers,
          ),
        ),
        Positioned(
          top: 40,
          left: 15,
          right: 15,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),

                SizedBox(width: 10),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: SearchAnchor(
                    builder: (BuildContext context, SearchController controller) {
                      return SearchBar(
                        controller: controller,
                        padding: const WidgetStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        onTap: () {
                          controller.openView();
                        },
                        onChanged: (_) {
                          controller.openView();
                        },
                        leading: const Icon(Icons.search),
                      );
                    },
                    suggestionsBuilder: (BuildContext context, SearchController controller) {
                      return List<ListTile>.generate(5, (int index) {
                        final String item = 'item $index';
                        return ListTile(
                          title: Text(item),
                          onTap: () {
                            setState(() {
                              controller.closeView(item);
                            });
                          },
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      red: 0,
                      green: 0,
                      blue: 0,
                      alpha: 0.1,
                    ),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
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
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_pin, size: 16),
                            SizedBox(width: 3),
                            Flexible(
                              // child: Text(
                              //   "Address",
                              //   style: TextStyle(fontSize: 16),
                              //   overflow: TextOverflow.ellipsis,
                              //   maxLines: 1,
                              // ),
                              child: TextField(
                                controller: _locationController,
                                readOnly: true,
                                style: TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Address",
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        ToggleButtonsRow(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ]),
    );
  }
}
