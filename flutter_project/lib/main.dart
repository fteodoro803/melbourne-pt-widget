import 'package:flutter/material.dart';
import "package:flutter_project/select_location_screen.dart";
import "package:flutter_project/select_route_type_screen.dart";
import "package:flutter_project/select_stop_screen.dart";
// add cupertino for apple version

import "ptv_api_service.dart";
import "api_response_screen.dart";
import 'package:global_configuration/global_configuration.dart';
import 'selections.dart';

// void main() {
void main() async {
  // Ensures Flutter bindings are initialised
  WidgetsFlutterBinding.ensureInitialized();

  // Loads Config
  await GlobalConfiguration().loadFromAsset("config");

  // Runs app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final selections = Selections();    // stores new user selections

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),

        // Pages/Screens
        routes: {
          '/apiResponse': (context) => ApiResponseScreen(),
          '/selectRouteTypeScreen': (context) => SelectRouteTypeScreen(userSelections: selections),
          '/selectLocationScreen': (context) => SelectLocationScreen(userSelections: selections),
          '/selectStopScreen': (context) => SelectStopScreen(userSelections: selections),
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
  PtvApiService ptv = PtvApiService();

  void handleRouteTypes() {
    setState(() {
      ptv.routeTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

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
              // DEV INPUT TESTING
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/apiResponse');
                },
                child: const Text('Go to API Response Viewer'),
              ),

              // ADD PAGE
              ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/selectRouteTypeScreen');
                  },
                  child: Text("+")),
            ],
          ),
        ),
      ),
    );
  }
}
