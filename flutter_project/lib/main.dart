import 'package:flutter/material.dart';
import "package:flutter_project/add_screens/confirmation_screen.dart";
import "package:flutter_project/add_screens/select_location_screen.dart";
import "package:flutter_project/add_screens/select_direction_screen.dart";
import "package:flutter_project/add_screens/select_route_type_screen.dart";
import "package:flutter_project/add_screens/select_stop_screen.dart";
import "package:flutter_project/dev/test_screen.dart";
import "package:flutter_project/screen_arguments.dart";
// add cupertino for apple version

import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/file_service.dart';

// void main() {
void main() async {
  // Ensures Flutter bindings are initialised
  WidgetsFlutterBinding.ensureInitialized();

  // Loads Config
  await GlobalConfiguration().loadFromAsset("config");

  // Runs app
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'PTV Widget App Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Demo Home Page'),
        // home: const TestScreen(),       // Test Screen for Devs

        // Pages/Screens
        routes: {
          '/selectRouteTypeScreen': (context) => SelectRouteTypeScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
          '/selectLocationScreen': (context) => SelectLocationScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
          '/selectStopScreen': (context) => SelectStopScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
          '/selectDirectionScreen': (context) => SelectDirectionScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
          '/confirmationScreen': (context) => ConfirmationScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final requestController = TextEditingController();
  final locationController = TextEditingController();
  String? _file;
  List<Transport> _transportList = [];

  @override
  void initState() {
    super.initState();
    _updateMainPage();
  }

  // Loads transport file and Converts JSON to list of Transport objects
  // I DONT LIKE HOW I DID THIS, FIND A WAY TO MAKE IT SIMPLER
  Future<void> _updateMainPage() async {
    String? stringContent = await read(formatted: true);

    if (stringContent != null) {
      List<Transport> transportList = await parseTransportJSON(stringContent);

      setState(() {
        _file = stringContent;
        _transportList = transportList;
      });
    } else {
      setState(() {
        _file = stringContent;
        _transportList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PTV App"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ADD PAGE BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/selectRouteTypeScreen',
                  arguments: ScreenArguments(Transport(), _updateMainPage),
                );
              },
              child: Text("+"),
            ),

            // TEST LIST TILE BUILDER (Scrollable ListView)
            Expanded(
              child: ListView.builder(
                itemCount: _transportList.length,
                itemBuilder: (context, index) {
                  final transport = _transportList[index];
                  return ListTile(
                    title: Text("${transport.routeType?.name} ${transport.route?.number} to ${transport.direction?.name}"),
                    isThreeLine: true,
                    subtitle: Text("from ${transport.stop?.name}\n"
                        "Next Departure: ${transport.departures?[0].estimatedDeparture ?? transport.departures?[0].scheduledDeparture}"),
                    onTap: () => {},
                  );
                },
              ),
            ),

            // SPACER
            SizedBox(height: 10),

            // TEST DISPLAY FILE CONTENTS (Scrollable Text Box)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "FILE TOSTRING:\n${_file != null
                      ? _file.toString()
                      : "null"}",
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.left,
                ),
              ),
            ),

            // REFRESH BUTTON
            ElevatedButton(
              onPressed: () {
                _updateMainPage();
              },
              child: Icon(Icons.refresh),
            ),

            // TEST BUTTON
            ElevatedButton(
              onPressed: () {
                _updateMainPage();
              },
              child: Text("TEST BUTTON"),
            ),
          ],
        ),
      ),
    );
  }
}
