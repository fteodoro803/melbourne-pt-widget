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

import 'utilities.dart' as utilities;

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

  // Reads the saved transport data from a file and converts it into a list of Transport objects.
  // If the file is empty or doesn't exist, initializes an empty transport list.
  Future<void> _updateMainPage() async {
    String? stringContent = await read(formatted: true);

    // Case: Populated transport File
    // Updates the Displayed Transport
    if (stringContent != null) {
      List<Transport> transportList = await parseTransportJSON(stringContent);

      // Updates Departures
      for (var transport in transportList) {
        await transport.updateDepartures();
      }

      // Saves updated Departures to File
      save(transportList);

      setState(() {
        _file = stringContent;
        _transportList = transportList;
      });
    }

    // Case: No transport File
    else {
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
                  final routeTypeName = transport.routeType?.name ?? "Null RouteTypeName";
                  final routeNumber = transport.route?.number ?? "Null RouteNumber";
                  final directionName = transport.direction?.name ?? "Null DirectionName";
                  final stopName = transport.stop?.name ?? "Null StopName";
                  var departure1 = "Null 1st Departure (INITIALISED)";
                  var departure2 = "Null 2nd Departure (INITIALISED)";
                  var departure3 = "Null 3rd Departure (INITIALISED)";

                  if (transport.departures != null && transport.departures!.length == 3) {
                    departure1 = utilities.getTime(transport.departures?[0].estimatedDeparture) ?? utilities.getTime(transport.departures?[0].scheduledDeparture) ?? "Null 1st Departure";
                    departure2 = utilities.getTime(transport.departures?[1].estimatedDeparture) ?? utilities.getTime(transport.departures?[1].scheduledDeparture) ?? "Null 2nd Departure";
                    departure3 = utilities.getTime(transport.departures?[2].estimatedDeparture) ?? utilities.getTime(transport.departures?[2].scheduledDeparture) ?? "Null 3rd Departure";
                  }

                  return ListTile(
                    isThreeLine: true,
                    title: Text("$routeTypeName $routeNumber to $directionName"),
                    subtitle: Text("from $stopName\n"
                        "$departure1 | $departure2 | $departure3"),
                    onTap: () => {},
                  );
                },
              ),
            ),

            // SPACER
            SizedBox(height: 10),

            // // TEST DISPLAY FILE CONTENTS (Scrollable Text Box)
            // Expanded(
            //   child: SingleChildScrollView(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Text(
            //       "FILE TOSTRING:\n${_file != null
            //           ? _file.toString()
            //           : "null"}",
            //       style: TextStyle(fontSize: 16.0),
            //       textAlign: TextAlign.left,
            //     ),
            //   ),
            // ),

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
