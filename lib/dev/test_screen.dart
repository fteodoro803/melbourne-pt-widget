import 'package:flutter/material.dart';
import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/ptv_info_classes/route_info.dart' as pt_route;

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  var ptvService = PtvService();

  List<pt_route.Route> _searchResults = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  Future<void> _searchRoutes() async {
    String searchQuery = _nameController.text;
    int? routeTypeId = int.tryParse(_typeController.text);
    RouteType? routeType = routeTypeId != null ? RouteType.fromId(routeTypeId) : null;
    final results = await ptvService.searchRoutes(query: searchQuery, routeType: routeType);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Screen")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Search Route Name',
              ),
            ),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Select Route Type',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _searchRoutes,
              child: const Text("Search"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final route = _searchResults[index];
                  return ListTile(
                    title: Text(route.name),
                    subtitle: Text(route.toString()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}