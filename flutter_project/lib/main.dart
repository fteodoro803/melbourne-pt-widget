import 'package:flutter/material.dart';
import "package:flutter_project/add_screens/confirmation_screen.dart";
import "package:flutter_project/add_screens/select_location_screen.dart";
import "package:flutter_project/add_screens/select_direction_screen.dart";
import "package:flutter_project/add_screens/select_route_type_screen.dart";
import "package:flutter_project/add_screens/select_stop_screen.dart";
// add cupertino for apple version

import "ptv_api_service.dart";
import 'package:global_configuration/global_configuration.dart';
import 'transport.dart';

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

  final selections = Transport();    // stores new user selections

  // This widget is the root of your application.
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
          '/selectRouteTypeScreen': (context) => SelectRouteTypeScreen(transport: selections),
          '/selectLocationScreen': (context) => SelectLocationScreen(transport: selections),
          '/selectStopScreen': (context) => SelectStopScreen(transport: selections),
          '/selectDirectionScreen': (context) => SelectDirectionScreen(transport: selections),
          '/confirmationScreen': (context) => ConfirmationScreen(transport: selections),
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
              // TRANSPORT OPTIONS DISPLAY
              // ListTiles of List<Transport>

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
