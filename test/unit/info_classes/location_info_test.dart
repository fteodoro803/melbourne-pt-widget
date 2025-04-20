import 'package:flutter_project/domain/location_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {

  group("Valid Input", () {
    late Location location;
    late String coordinates;
    late String name;
    late LatLng latLng;
    
    setUp( () {
      name = "Melbourne Central";
      coordinates = "-37.81014283296091, 144.96274374042267";
      latLng = LatLng(-37.81014283296091, 144.96274374042267);
    });

    test("Valid coordinates", () {
      location = Location(coordinates: coordinates);
      
      expect(location.latitude, -37.81014283296091);
      expect(location.longitude, 144.96274374042267);
      expect(location.coordinates, "-37.81014283296091, 144.96274374042267");
      expect(location.name, null);
    });

    test("Valid coordinates with name", () {
      location = Location(coordinates: coordinates, name: name);

      expect(location.latitude, -37.81014283296091);
      expect(location.longitude, 144.96274374042267);
      expect(location.coordinates, "-37.81014283296091, 144.96274374042267");
      expect(location.name, "Melbourne Central");
    });

    test("Valid LatLng", () {
      location = Location.withLatLng(latLng);

      expect(location.latitude, -37.81014283296091);
      expect(location.longitude, 144.96274374042267);
      expect(location.coordinates, "-37.81014283296091, 144.96274374042267");
      expect(location.name, null);
    });

    test("Valid LatLng with name", () {
      location = Location.withLatLng(latLng, name: name);

      expect(location.latitude, -37.81014283296091);
      expect(location.longitude, 144.96274374042267);
      expect(location.coordinates, "-37.81014283296091, 144.96274374042267");
      expect(location.name, "Melbourne Central");
    });
  });

  group("Invalid Input", () {
    test("Empty coordinates", () {
      String coordinates = "";
      expect( () => Location(coordinates: coordinates), throwsFormatException);
    });

    test("Improper format (insufficient values)", () {
      String coordinates = "-37.81";
      expect( () => Location(coordinates: coordinates), throwsFormatException);
    });

    test("Improper format (too many values)", () {
      String coordinates = "-37.81, 144.96, 144.12";
      expect( () => Location(coordinates: coordinates), throwsFormatException);
    });

    test("Improper format (some invalid values)", () {
      String coordinates = "-37.81, 144.96abc";
      expect( () => Location(coordinates: coordinates), throwsFormatException);
    });
  });

  group("Edge Cases", () {});

  group("Class Methods", () {
    test("toLatLng() function", () {
      Location location = Location(coordinates: "-37.81014283296091, 144.96274374042267");
      LatLng result = location.toLatLng();

      expect(result.latitude, -37.81014283296091);
      expect(result.longitude, 144.96274374042267);
    });
  });
}