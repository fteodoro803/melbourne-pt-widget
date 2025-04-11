import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_project/add_screens_old/confirmation_screen.dart";
import "package:flutter_project/add_screens_old/select_location_screen.dart";
import "package:flutter_project/add_screens_old/select_direction_screen.dart";
import "package:flutter_project/add_screens_old/select_route_type_screen.dart";
import "package:flutter_project/add_screens_old/select_stop_screen.dart";
import "package:flutter_project/database/database.dart";
import "package:flutter_project/ptv_service.dart";
import "package:flutter_project/add_screens/widgets/bottom_navigation_bar.dart";
import "package:flutter_project/add_screens/widgets/custom_list_tile.dart";
import "package:flutter_project/screen_arguments.dart";
// add cupertino for apple version

import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_project/transport.dart';
import 'package:flutter_project/file_service.dart';

import 'package:flutter_project/dev/test_screen.dart';

import "add_screens/find_routes_screen.dart";
import "add_screens/search_details.dart";
import "add_screens/search_screen.dart";
import "home_widget_service.dart";

import 'package:get/get.dart';

// void main() {
void main() async {
  // Ensures Flutter bindings are initialised
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(AppDatabase());

  // todo: maybe call fetchRoutes here?

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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        initialRoute: '/',

        // Pages/Screens
        routes: {
          '/': (context) => const MyHomePage(title: "Demo Home Page"),
          '/selectRouteTypeScreen': (context) => SelectRouteTypeScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
          '/findRoutesScreen': (context) => FindRoutesScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
          '/selectLocationScreen': (context) => SelectLocationScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
                  as ScreenArguments),
          '/searchScreen': (context) => SearchScreen(
              arguments: ModalRoute.of(context)!.settings.arguments
              as ScreenArguments,
              searchDetails: SearchDetails(),
              enableSearch: true,
          ),
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
  PtvService ptvService = PtvService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    print("initState called");
    // _updateMainPage();

    // Get all Routes and RouteTypes, and add to Database
    _initialisePTVData();

    // Initialise home widgets
    //_initializeHomeWidgetAsync();
    homeWidgetService.initialiseHomeWidget();

    _updateMainPage();

    // Set up a timer to update the transport list every 30 seconds
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      print("Timer triggered");
      _updateMainPage();
    });
  }

  // // Maybe no longer needed to be async??
  // Future<void> _initializeHomeWidgetAsync() async {
  //   await homeWidgetService.initialiseHomeWidget();
  // }

  Future<void> _initialisePTVData() async {
    // todo: add logic to skip this, if it's already been done
    await ptvService.fetchRouteTypes();
    await ptvService.fetchRoutes();
  }

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

  // Function to handle the reorder action
  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Transport item = _transportList.removeAt(oldIndex);
      _transportList.insert(newIndex, item);
    });

    // Save the updated list after reordering
    save(_transportList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Routes"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FindRoutesScreen(arguments: ScreenArguments(_updateMainPage)),
              ));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Divider(),

            // INFORMATION TILES AS LIST
            Expanded(
              child: RefreshIndicator(
                onRefresh: _updateMainPage,
                child: ReorderableListView(
                  onReorder: onReorder,
                  children: [
                    for (int index = 0; index < _transportList.length; index++)
                      Card(
                        key: ValueKey(_transportList[index].hashCode),
                        margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 6.0),
                        elevation: 4,
                        child: CustomListTile(
                          transport: _transportList[index],
                          dismissible: true,
                          onDismiss: () => {removeTransport(_transportList[index]), _updateMainPage()},
                          onTap: () =>
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchScreen(arguments: ScreenArguments(_updateMainPage), searchDetails: SearchDetails.withTransport(_transportList[index]), enableSearch: false)
                            ),
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      // Add the refresh button as a floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: _updateMainPage,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
      // Add the bottom navigation bar
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0, // Home page is index 0
        updateMainPage: _updateMainPage,
      ),
    );
  }
}
