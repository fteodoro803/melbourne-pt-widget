import 'package:flutter/material.dart';

// Google Maps
import 'package:google_maps_flutter/google_maps_flutter.dart';


class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-37.813812122509205, 144.96358311072478);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(target: _center, zoom: 11)
      ),
    );
  }
}
