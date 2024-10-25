import 'dart:io';
import 'package:flutter/foundation.dart';
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

Future<void> append(String data) async {
  try {
    // Get the path to the application documents directory
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');

    // Open the file for appending
    if (await file.exists()) {
      // Append the new data to the file
      await file.writeAsString(data, mode: FileMode.append);
    }
    else {
      // If the file doesn't exist, create it and write the new data
      await file.writeAsString(data);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error appending to file: $e');
    } // Log the error
  }
}

// Read JSON File
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