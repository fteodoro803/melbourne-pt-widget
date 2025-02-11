import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/transport.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getLocalPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<void> save(List<Transport> transportList) async {
  try {
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');

    List<Map<String, dynamic>> transports = [];

    // Convert each Transport to JSON
    for (var transport in transportList) {
      transports.add(transport.toJson());
    }

    // Convert to prettified JSON String
    const encoder = JsonEncoder.withIndent('  ');
    String prettyString = encoder.convert(transports);

    // Save updated list to File
    await file.writeAsString(prettyString);

  } catch (e) {
    if (kDebugMode) {
      print('Error saving to file: $e');
    } // Log the error
  }
}

// add delete functionality

Future<void> append(Transport newTransport) async {
  try {
    // Get the path to the application documents directory
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');

    List<Map<String, dynamic>> transports = [];

    // Open the file for appending
    if (await file.exists()) {
      String content = await file.readAsString();
      // Decode content to json
      if (content.isNotEmpty) {
        transports = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
    }

    // Add new transport to JSON Map
    transports.add(newTransport.toJson());

    // Convert to prettified JSON String
    const encoder = JsonEncoder.withIndent('  ');
    String prettyString = encoder.convert(transports);

    // Save updated list to File
    await file.writeAsString(prettyString);

  } catch (e) {
    if (kDebugMode) {
      print('Error appending to file: $e');
    } // Log the error
  }
}

// Read JSON File as String
Future<String?> read({bool formatted = false}) async {
  try {
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');
    String string = await file.readAsString();

    //test printing~
    if (kDebugMode) {
      print("Reading from Path: $path");
    }

    // Conversion to Pretty JSON String
    if (string.isNotEmpty && formatted == true) {
      final jsonObject = jsonDecode(string);
      final prettyString = JsonEncoder.withIndent('   ').convert(jsonObject);
      return prettyString;
    }

    return string;
  } catch (e) {
    // Handle error (file not found, etc.)
    return null;
  }
}

// Convert JSON String to Transport objects
Future<List<Transport>> parseTransportJSON(String jsonString) async {
  // Decode the JSON string into a list of dynamic maps
  List<dynamic> jsonList = jsonDecode(jsonString);

  // Convert each JSON map to a Transport instance
  List<Transport> transports = [];

  for (var json in jsonList) {
    Transport transport = Transport.fromJson(json);
    // print("testParseJSON: ${transport.toString()}\n");
    transports.add(transport);
  }

  return transports;
}