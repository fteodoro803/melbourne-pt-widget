import 'package:flutter/material.dart';
import "package:flutter_project/add_screens/confirmation_screen.dart";
import "package:flutter_project/add_screens/select_location_screen.dart";
import "package:flutter_project/add_screens/select_direction_screen.dart";
import "package:flutter_project/add_screens/select_route_type_screen.dart";
import "package:flutter_project/add_screens/select_stop_screen.dart";
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
  // final List<Transport> transportList = [];

  // // Updates the Main Page in response to changes in Confirmation screen
  // void updateMainPage() {
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'PTV Widget App Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Demo Home Page'),

        // Pages/Screens
        routes: {
          // '/selectRouteTypeScreen': (context) => SelectRouteTypeScreen(arguments: ScreenArguments(Transport())),
          '/selectRouteTypeScreen': (context) => SelectRouteTypeScreen(arguments: ModalRoute.of(context)!.settings.arguments as ScreenArguments),
          '/selectLocationScreen': (context) => SelectLocationScreen(arguments: ModalRoute.of(context)!.settings.arguments as ScreenArguments),
          '/selectStopScreen': (context) => SelectStopScreen(arguments: ModalRoute.of(context)!.settings.arguments as ScreenArguments),
          '/selectDirectionScreen': (context) => SelectDirectionScreen(arguments: ModalRoute.of(context)!.settings.arguments as ScreenArguments),
          '/confirmationScreen': (context) => ConfirmationScreen(arguments: ModalRoute.of(context)!.settings.arguments as ScreenArguments),
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

  @override
  void initState() {
    super.initState();
    _loadFile(); // Call the method to load the file content
  }

  Future<void> _loadFile() async {
    String? content = await read();
    setState(() {
      _file = content;
    });
  }

  // Updates the Main Page in response to changes in Confirmation screen
  void _updateMainPage() async {
    await append("updated - ${DateTime.now().toLocal()}\n");
    await _loadFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PTV App"),
        centerTitle: true,
      ),
      body: SafeArea(
        // Safe area is so the UI elements are below the notch
        child: Center(
          child: Column(
            children: [
              // ADD PAGE
              ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/selectRouteTypeScreen', arguments: ScreenArguments(Transport(), _updateMainPage));
                  },
                  child: Text("+")
              ),

              // TEST DISPLAY FILE CONTENTS
              SizedBox(height: 20), // Add some spacing
              // Display the contents of the text file
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _file.toString() ?? "null",
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
              ),

              // TRANSPORT OPTIONS DISPLAY
              // ListTiles of List<Transport>

              ElevatedButton(
                  onPressed: () {
                    _updateMainPage();
                  },
                  child: Text("TEST BUTTON")
              ),
            ],
          ),
        ),
      ),
    );
  }
}
