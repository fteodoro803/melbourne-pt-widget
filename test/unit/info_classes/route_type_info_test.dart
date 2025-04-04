import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Train
  group("Train Initialisation", () {
    test("Initialising train via ID", () {
      // Arrange
      int trainId = 0;

      // Act
      RouteType result = RouteType.fromId(trainId);

      //Assert
      expect(result, equals(RouteType.train));
    });

    test("Initialising train via Name", () {
      // Arrange
      String trainName = "train";

      // Act
      RouteType result = RouteType.fromName(trainName);

      //Assert
      expect(result, equals(RouteType.train));
    });
  });

  // Tram
  group("Tram Initialisation", () {
    test("Initialising tram via ID", () {
      // Arrange
      int tramId = 1;

      // Act
      RouteType result = RouteType.fromId(tramId);

      //Assert
      expect(result, equals(RouteType.tram));
    });

    test("Initialising tram via Name", () {
      // Arrange
      String tramName = "tram";

      // Act
      RouteType result = RouteType.fromName(tramName);

      //Assert
      expect(result, equals(RouteType.tram));
    });
  });

  // Bus
  group("Bus Initialisation", () {
    test("Initialising bus via ID", () {
      // Arrange
      int busId = 2;

      // Act
      RouteType result = RouteType.fromId(busId);

      //Assert
      expect(result, equals(RouteType.bus));
    });

    test("Initialising vLine via Name", () {
      // Arrange
      String busName = "bus";

      // Act
      RouteType result = RouteType.fromName(busName);

      //Assert
      expect(result, equals(RouteType.bus));
    });
  });

  // vLine
  group("vLine Initialisation", () {
    test("Initialising vLine via ID", () {
      // Arrange
      int vLineId = 3;

      // Act
      RouteType result = RouteType.fromId(vLineId);

      //Assert
      expect(result, equals(RouteType.vLine));
    });

    test("Initialising vLine via Name", () {
      // Arrange
      String vLineName = "vLine";

      // Act
      RouteType result = RouteType.fromName(vLineName);

      //Assert
      expect(result, equals(RouteType.vLine));
    });
  });

  // Name Normalisation
  group("Name Normalisation", () {
    test("Uppercase", () {
      String name = "TRAM";
      expect(RouteType.fromName(name), RouteType.tram);

      name = "tRAm";
      expect(RouteType.fromName(name), RouteType.tram);
    });

    test("Spaces", () {
      String name = "t r a m";
      expect(RouteType.fromName(name), RouteType.tram);

      name = "tram ";
      expect(RouteType.fromName(name), RouteType.tram);

      name = "     tram ";
      expect(RouteType.fromName(name), RouteType.tram);
    });
  });

  // Non-Initialisation
  group("Invalid Initialisation", () {
    test("Initialising via ID", () {
      // Arrange
      int id = -2;

      // Act & Assert
      expect( () => RouteType.fromId(id), throwsArgumentError);
    });

    test("Initialising via Name", () {
      // Arrange
      String name = "busz";

      // Act & Assert
      expect( () => RouteType.fromName(name), throwsArgumentError);
    });
  });
}
