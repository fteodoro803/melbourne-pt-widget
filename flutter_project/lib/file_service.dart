import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/transport.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getLocalPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<void> save(String data) async {
  final path = await getLocalPath();
  final file = File('$path/transport_data.json');
  // String jsonString = json.encode(userData.toJson());
  await file.writeAsString(data);
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

    // Save updated list to File
    await file.writeAsString(jsonEncode(transports));

  } catch (e) {
    if (kDebugMode) {
      print('Error appending to file: $e');
    } // Log the error
  }
}

// Read JSON File as String
Future<String?> read() async {
  try {
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');
    String string = await file.readAsString();
    String jsonString = string;   // convert to jsonstring (IMPLEMENT THIS)

    //test printing~
    if (kDebugMode) {
      print("Reading from Path: $path");
    }

    return jsonString;
  } catch (e) {
    // Handle error (file not found, etc.)
    return null;
  }
}