import "dart:io";

import 'package:flutter/material.dart';
import "ptv_api_service.dart";
import "utilities.dart";
import "api_response_screen.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        routes: {
          '/apiResponse': (context) => ApiResponseScreen(),
        }
    );
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
      body: SafeArea(
        // Safe area is so the UI elements are below the notch
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/apiResponse');
              },
              child: const Text('Go to API Response Viewer'),
            ),
            Row(
              children: [
                Text("Request: "),
                SizedBox(
                    width: 300,
                    child: TextField(
                      controller: requestController,
                      decoration: InputDecoration(),
                    )),
              ],
            ),
            Row(
              children: [
                Text("Location: "),
                SizedBox(
                    width: 250,
                    child: TextField(
                      controller: locationController,
                      decoration: InputDecoration(),
                    )),
                ElevatedButton(onPressed: getLocation, child: Text("Auto")),
              ],
            ),
            ElevatedButton(
                onPressed: handleRouteTypes, child: Text("RouteTypes")),
          ],
        ),
      ),
    );
  }
}
