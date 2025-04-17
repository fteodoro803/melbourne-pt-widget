import 'package:flutter/material.dart';
import 'package:flutter_project/dev/dev_tools.dart';
import 'package:flutter_project/ptv_info_classes/route_direction_info.dart';
import 'package:flutter_project/ptv_service.dart';
import 'package:flutter_project/screen_arguments.dart';

import 'package:flutter_project/database/database.dart' as db;
import 'package:get/get.dart';
import 'package:flutter_project/database/helpers/directionHelpers.dart';

class SelectDirectionScreen extends StatefulWidget {
  const SelectDirectionScreen({super.key, required this.arguments});

  // Stores user Transport details
  final ScreenArguments arguments;

  @override
  State<SelectDirectionScreen> createState() => _SelectDirectionScreenState();
}

class _SelectDirectionScreenState extends State<SelectDirectionScreen> {
  final String _screenName = "selectDirection";
  List<RouteDirection> _directions = [];
  PtvService ptvService = PtvService();
  DevTools tools = DevTools();

  // Initialising State
  @override
  void initState() {
    super.initState();
    getDirections();

    // Debug Printing
    tools.printScreenState(_screenName, widget.arguments);
  }

  void getDirections() async {
    int? routeId = widget.arguments.transport!.route?.id;
    List<RouteDirection> directions = await ptvService.fetchDirections(routeId!);
    _directions = directions;
    setState(() {});
  }

  void setDirection(int? index) {
    if (index != null) {
      widget.arguments.transport!.direction = _directions[index];

      int id = _directions[index].id;
      String name = _directions[index].name;
      String description = _directions[index].description;
      int? routeId = widget.arguments.transport?.route?.id;

      Get.find<db.AppDatabase>().addDirection(id, name, description, routeId!);
    }
    else {
      widget.arguments.transport!.direction = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Direction:"),
        centerTitle: true,
      ),

      // Generates List of Stops
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                // old
                itemCount: _directions.length,
                itemBuilder: (context, index) {
                  final directionName =
                      _directions[index].name;
                  final directionId =
                      _directions[index].id;

                  return ListTile(
                    title: Text("$directionName ($directionId)"),
                    onTap: () {
                      setDirection(index);
                      Navigator.pushNamed(context, '/confirmationScreen',
                          arguments: widget.arguments);
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
                onPressed: () => {
                  setDirection(null),
                  Navigator.pushNamed(context, '/confirmationScreen',
                          arguments: widget.arguments),
                },
                child: Text("Skip"))
          ],
        ),
      ),
    );
  }
}
