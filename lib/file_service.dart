import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/domain/trip.dart';
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

// Future<void> append(Transport newTransport) async {
//   try {
//     // Get the path to the application documents directory
//     final path = await getLocalPath();
//     final file = File('$path/transport_data.json');
//
//     List<Map<String, dynamic>> transports = [];
//
//     // Open the file for appending
//     if (await file.exists()) {
//       String content = await file.readAsString();
//       // Decode content to json
//       if (content.isNotEmpty) {
//         transports = List<Map<String, dynamic>>.from(jsonDecode(content));
//       }
//     }
//
//     // Add new transport to JSON Map
//     transports.add(newTransport.toJson());
//
//     // Convert to prettified JSON String
//     const encoder = JsonEncoder.withIndent('  ');
//     String prettyString = encoder.convert(transports);
//
//     // Save updated list to File
//     await file.writeAsString(prettyString);
//
//   } catch (e) {
//     if (kDebugMode) {
//       print('Error appending to file: $e');
//     } // Log the error
//   }
// }

Future<void> append(Transport newTransport) async { // I think you can compare it to the transport list in the context rather than save file
  try {
    // Get the path to the application documents directory
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');

    // List to hold the transports
    List<Map<String, dynamic>> transports = [];

    // Check if the file exists
    if (await file.exists()) {
      String content = await file.readAsString();
      // Decode content to JSON
      if (content.isNotEmpty) {
        transports = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
    }

    // Convert transports to list of Transport objects
    List<Transport> transportList = transports.map((transportJson) => Transport.fromJson(transportJson)).toList();

    // Check if the newTransport is already in the list
    bool isTransportAlreadySaved = transportList.any((existingTransport) => existingTransport.isEqualTo(newTransport));

    if (!isTransportAlreadySaved) {
      // If transport is not already saved, add it to the list
      transports.add(newTransport.toJson());

      // Convert to prettified JSON string
      const encoder = JsonEncoder.withIndent('  ');
      String prettyString = encoder.convert(transports);

      // Save updated list to the file
      await file.writeAsString(prettyString);
    } else {
      // Optionally, log that the transport is already saved
      if (kDebugMode) {
        print('Transport is already saved, skipping append.');
      }
    }

  } catch (e) {
    if (kDebugMode) {
      print('Error appending to file: $e');
    }
  }
}

Future<bool> isTransportSaved(Transport transport) async {
  try {
    // Get the path to the application documents directory
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');

    // Check if the file exists
    if (await file.exists()) {
      String content = await file.readAsString();

      // Decode content to JSON
      if (content.isNotEmpty) {
        // Decode JSON into a list of Transport objects
        List<Map<String, dynamic>> transports = List<Map<String, dynamic>>.from(jsonDecode(content));
        List<Transport> transportList = transports.map((json) => Transport.fromJson(json)).toList();

        // Check if the transport is already in the list
        bool isAlreadySaved = transportList.any((existingTransport) => existingTransport.isEqualTo(transport));

        return isAlreadySaved;
      }
    }

    return false; // Return false if the file does not exist or if the transport is not found
  } catch (e) {
    if (kDebugMode) {
      print('Error checking if transport is saved: $e');
    }
    return false; // Return false in case of an error
  }
}

Future<void> deleteMatchingTransport(Transport newTransport) async {
  try {
    // Get the path to the application documents directory
    final path = await getLocalPath();
    final file = File('$path/transport_data.json');

    // List to hold the transports
    List<Map<String, dynamic>> transports = [];

    // Check if the file exists
    if (await file.exists()) {
      String content = await file.readAsString();
      // Decode content to JSON
      if (content.isNotEmpty) {
        transports = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
    }

    // Find the transport that matches all details of newTransport
    transports.removeWhere((existingTransport) {
      // Check if all relevant fields match
      return Transport.fromJson(existingTransport).isEqualTo(newTransport); // Assuming `isEqualTo` is a method that compares Transport
    });

    // Convert the updated list back to a prettified JSON string
    const encoder = JsonEncoder.withIndent('  ');
    String prettyString = encoder.convert(transports);

    // Save the updated list back to the file
    await file.writeAsString(prettyString);

  } catch (e) {
    if (kDebugMode) {
      print('Error deleting from file: $e');
    }
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
      print("( file_service.dart -> read() ): Reading from Path: $path");
    }

    // Conversion to Pretty JSON String
    if (string.isNotEmpty && formatted == true) {
      final jsonObject = jsonDecode(string);
      final prettyString = JsonEncoder.withIndent('   ').convert(jsonObject);

      // // Print the pretty string
      // if (kDebugMode) {
      //   print("( file_service.dart -> read() ): Pretty JSONString: $string");
      // }

      return prettyString;
    }

    // // test
    // if (kDebugMode) {
    //   print("( file_service.dart -> read() ): JSONString: $string");
    // }

    return string;
  } catch (e) {
    // Handle error (file not found, etc.)
    return null;
  }
}

// Convert JSON String to Transport objects
Future<List<Transport>> parseTransportJSON(String jsonString) async {
  // Convert each JSON map to a Transport instance
  List<Transport> transports = [];

  // Checks if jsonString is empty, and returns empty List if it is
  if (jsonString.isEmpty) {
    return [];
  }

  // Decode the JSON string into a list of dynamic maps
  List<dynamic> jsonList = jsonDecode(jsonString);

  for (var json in jsonList) {
    Transport transport = Transport.fromJson(json);
    // print("testParseJSON: ${transport.toString()}\n");
    transports.add(transport);
  }

  return transports;
}

// Save GeoPath CSV
Future<void> saveGeoPath(String geoPath) async {
  try {
    final path = await getLocalPath();
    final file = File('$path/transport_geopath.csv');
    // Save updated list to File
    await file.writeAsString(geoPath);

  } catch (e) {
    if (kDebugMode) {
      print('Error saving to file: $e');
    } // Log the error
  }
}