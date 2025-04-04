import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Train
  group("Train Initialisation", () {
    test("Initialising train via ID", () {
      // Arrange
      int trainId = 0;

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromId(trainId);

      //Assert
      expect(result, equals(RouteTypeEnum.train));
    });

    test("Initialising train via Name", () {
      // Arrange
      String trainName = "train";

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromName(trainName);

      //Assert
      expect(result, equals(RouteTypeEnum.train));
    });
  });

  // Tram
  group("Tram Initialisation", () {
    test("Initialising tram via ID", () {
      // Arrange
      int tramId = 1;

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromId(tramId);

      //Assert
      expect(result, equals(RouteTypeEnum.tram));
    });

    test("Initialising tram via Name", () {
      // Arrange
      String tramName = "tram";

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromName(tramName);

      //Assert
      expect(result, equals(RouteTypeEnum.tram));
    });
  });

  // Bus
  group("Bus Initialisation", () {
    test("Initialising bus via ID", () {
      // Arrange
      int busId = 2;

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromId(busId);

      //Assert
      expect(result, equals(RouteTypeEnum.bus));
    });

    test("Initialising vLine via Name", () {
      // Arrange
      String busName = "bus";

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromName(busName);

      //Assert
      expect(result, equals(RouteTypeEnum.bus));
    });
  });

  // vLine
  group("vLine Initialisation", () {
    test("Initialising vLine via ID", () {
      // Arrange
      int vLineId = 3;

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromId(vLineId);

      //Assert
      expect(result, equals(RouteTypeEnum.vLine));
    });

    test("Initialising vLine via Name", () {
      // Arrange
      String vLineName = "vLine";

      // Act
      RouteTypeEnum result = RouteTypeEnum.fromName(vLineName);

      //Assert
      expect(result, equals(RouteTypeEnum.vLine));
    });
  });

  // Name Normalisation
  group("Name Normalisation", () {
    test("Uppercase", () {
      String name = "TRAM";
      expect(RouteTypeEnum.fromName(name), RouteTypeEnum.tram);

      name = "tRAm";
      expect(RouteTypeEnum.fromName(name), RouteTypeEnum.tram);
    });

    test("Spaces", () {
      String name = "t r a m";
      expect(RouteTypeEnum.fromName(name), RouteTypeEnum.tram);

      name = "tram ";
      expect(RouteTypeEnum.fromName(name), RouteTypeEnum.tram);

      name = "     tram ";
      expect(RouteTypeEnum.fromName(name), RouteTypeEnum.tram);
    });
  });

  // Non-Initialisation
  group("Invalid Initialisation", () {
    test("Initialising via ID", () {
      // Arrange
      int id = -2;

      // Act & Assert
      expect( () => RouteTypeEnum.fromId(id), throwsArgumentError);
    });

    test("Initialising via Name", () {
      // Arrange
      String name = "busz";

      // Act & Assert
      expect( () => RouteTypeEnum.fromName(name), throwsArgumentError);
    });
  });
}
