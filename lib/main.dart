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
import "package:flutter_speed_dial/flutter_speed_dial.dart";
// add cupertino for apple version

import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_project/domain/trip.dart';
import 'package:flutter_project/file_service.dart';

import 'package:flutter_project/dev/test_screen.dart';
import "add_screens/search_binding.dart";
import "add_screens/find_routes_screen.dart";

import "add_screens/search_screen.dart";
import "home_widget_service.dart";

import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() async {
  tzdata.initializeTimeZones();
  // Ensures Flutter bindings are initialised
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(AppDatabase());

  // todo: maybe call fetchRoutes here?

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
    return GetMaterialApp(
        title: 'PTV Widget App Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        initialRoute: '/',
        getPages: [
          GetPage(
            name: '/',
            page: () => const MyHomePage(title: "Demo Home Page"),
          ),
          GetPage(
            name: '/search',
              page: () {
                final args = Get.arguments as Map<String, dynamic>?;

                return SearchScreen(
                  route: args?['route'],
                  trip: args?['trip'],
                  enableSearch: args?['enableSearch'] ?? false,
                );
              },
              binding: BindingsBuilder(() {})
          ),
          GetPage(
              name: '/findRoutes',
              page: () => FindRoutesScreen(),
              binding: BindingsBuilder(() {})
          ),
          GetPage(
              name: '/testScreen',
              page: () => TestScreen(),
              binding: BindingsBuilder(() {})
          )
        ],

        // Pages/Screens
        routes: {
          '/': (context) => const MyHomePage(title: "Demo Home Page"),
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
  List<Trip> _tripList = [];

  HomeWidgetService homeWidgetService = HomeWidgetService();
  PtvService ptvService = PtvService();
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Get all Routes and RouteTypes, and add to Database
    _initialisePTVData();

    // Initialise home widgets
    //_initializeHomeWidgetAsync();
    homeWidgetService.initialiseHomeWidget();

    _updateMainPage();

    // Set up a timer to update the main page every 30 seconds
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
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

  // Reads the saved trip data from database and updates departures
  Future<void> _updateMainPage() async {
    print("Updating main page");

    List<Trip> tripList = await ptvService.loadTrips();

    // Updates all Departures
    for (var trip in tripList) {
      await trip.updateDepartures(departureCount: 3);
    }

    setState(() {
      _tripList = tripList;
    });

    // print("( main.dart ) -- preparing to send Widget Data");
    // Send Trips Data to Widget
    await homeWidgetService.sendWidgetData(_tripList);
    print("( main.dart ) -- Widget Data finishing sending");
  }

  @override
  void dispose() {
    // Cancel the timer when the screen is disposed
    _timer.cancel();

    super.dispose();
  }

  // Function to handle the reorder action
  void onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Trip item = _tripList.removeAt(oldIndex);
      _tripList.insert(newIndex, item);
    });

    // Save the updated list after reordering
    save(_tripList);

    // Save indices to database
    for (int i=0; i<_tripList.length; i++) {
      _tripList[i].setIndex(i);
      await ptvService.saveTrip(_tripList[i]);
    }
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
            ElevatedButton(onPressed: () => Get.to(() => TestScreen()), child: Text("Go to Test Screen")),      // todo: remove this in final version
            Divider(),

            // INFORMATION TILES AS LIST
            Expanded(
              child: RefreshIndicator(
                onRefresh: _updateMainPage,
                child: ReorderableListView(
                  onReorder: onReorder,
                  children: [
                    for (int index = 0; index < _tripList.length; index++)
                      Card(
                        key: ValueKey(_tripList[index].hashCode),
                        margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 6.0),
                        elevation: 4,
                        child: CustomListTile(
                          transport: _tripList[index],
                          dismissible: true,
                          onDismiss: () async {
                            await ptvService.deleteTrip(_tripList[index].uniqueID!);
                            await _updateMainPage();
                          },
                          onTap: () =>
                            Get.to(
                              () => SearchScreen(trip: _tripList[index], enableSearch: false),
                              binding: SearchBinding(),
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
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,

      foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 10,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: Icon(Icons.route),
            label: 'See All Routes',
            labelStyle: TextStyle(fontSize: 16),
            onTap: () => Get.to(() => FindRoutesScreen()),
          ),
          SpeedDialChild(
            child: Icon(Icons.search),
            label: 'Map Search',
            labelStyle: TextStyle(fontSize: 16),
            onTap: () => Get.to(() => SearchScreen(
              enableSearch: true,
            ),
              binding: SearchBinding(),
            ),
          ),
        ],
      ),

      // Add the bottom navigation bar
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0, // Home page is index 0
        updateMainPage: _updateMainPage,
      ),
    );
  }
}
