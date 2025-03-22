import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_project/add_screens/confirmation_screen.dart";
import "package:flutter_project/add_screens/select_location_screen.dart";
import "package:flutter_project/add_screens/select_direction_screen.dart";
import "package:flutter_project/add_screens/select_route_type_screen.dart";
import "package:flutter_project/add_screens/select_stop_screen.dart";
import "package:flutter_project/custom_list_tile.dart";
import "package:flutter_project/screen_arguments.dart";
// add cupertino for apple version

import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/file_service.dart';

import 'package:flutter_project/dev/test_screen.dart';

import "add_screens/transport_details_screen.dart";
import "home_widget_service.dart";



// void main() {
void main() async {
  // Ensures Flutter bindings are initialised
  WidgetsFlutterBinding.ensureInitialized();

  // // Loads Config
  // await GlobalConfiguration().loadFromAsset("config");
  //
  // // Runs app
  // runApp(MyApp());
  try {
    await GlobalConfiguration().loadFromAsset("config");
    runApp(MyApp());
  } catch (e) {
    print("Error during initialization: $e");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
          '/testScreen': (context) => const TestScreen(),
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

  HomeWidgetService homeWidgetService = HomeWidgetService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print("initState called");
    // _updateMainPage();

    // Initialise home widgets
    //_initializeHomeWidgetAsync();
    homeWidgetService.initialiseHomeWidget();

    _updateMainPage();

    // Set up a timer to update the transport list every 30 seconds
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      print("Timer triggered");
      _updateMainPage();
    });
  }

  // // Maybe no longer needed to be async??
  // Future<void> _initializeHomeWidgetAsync() async {
  //   await homeWidgetService.initialiseHomeWidget();
  // }

  // Reads the saved transport data from a file and converts it into a list of Transport objects.
  // If the file is empty or doesn't exist, initializes an empty transport list.
  Future<void> _updateMainPage() async {
    print("updating main page");
    String? stringContent = await read(formatted: true);

    // Case: Populated transport File
    // Updates the Displayed Transport
    if (stringContent != null) {
      List<Transport> transportList = await parseTransportJSON(stringContent);

      // Updates all Departures
      for (var transport in transportList) {
        await transport.updateDepartures();
      }

      // Saves updated Departures to File
      save(transportList);

      setState(() {
        _file = stringContent;
        _transportList = transportList;
      });

      print("( main.dart ) -- preparing to send Widget Data");
      // Send Transport Data to Widget
      await homeWidgetService.sendWidgetData(_transportList);
      print("( main.dart ) -- Widget Data finishing sending");
    }

    // Case: No transport File
    else {
      setState(() {
        _file = stringContent;
        _transportList = [];
      });
    }
  }

  // Dismiss a Transport item from List
  void removeTransport(Transport transport) async {
    setState(() {
      _transportList.remove(transport);
    });

    await save(_transportList);   // Updates the save file
    print("( main.dart -> removeTransport() ) : TransportListCount=${_transportList.length}");
  }

  @override
  void dispose() {
    // Cancel the timer when the screen is disposed
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Routes"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Divider(),

            // INFORMATION TILES AS LIST
            Expanded(
              child: ListView.builder(
                itemCount: _transportList.length,
                itemBuilder: (context, index) {
                  final transport = _transportList[index];
                  return CustomListTile(transport: transport, dismissible: true, onDismiss: () => {removeTransport(transport), _updateMainPage()},
                  onTap: () =>
                    // Navigate to TransportDetailsScreen with transport data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransportDetailsScreen(transport: transport),
                      ),
                    )
                  );
                },
              ),
            ),

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

            Divider(),

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
                Navigator.pushNamed(context, '/testScreen');
              },
              child: Text("TEST BUTTON"),
            ),
          ],
        ),
      ),
    );
  }
}
