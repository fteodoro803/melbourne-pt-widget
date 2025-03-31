import 'package:flutter_project/ptv_info_classes/route_type_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Train
  group("Train Initialisation", () {
    test("Initialising train via ID", () {
      // Arrange
      RouteType train;
      int trainId = 0;

      // Act
      train = RouteType.withId(id: trainId);
      RouteTypeEnum result = train.type;

      //Assert
      expect(result, equals(RouteTypeEnum.train));
    });

    test("Initialising train via Name", () {
      // Arrange
      RouteType train;
      String trainName = "train";

      // Act
      train = RouteType.withName(name: trainName);
      RouteTypeEnum result = train.type;

      //Assert
      expect(result, equals(RouteTypeEnum.train));
    });
  });

  // Tram
  group("Tram Initialisation", () {
    test("Initialising tram via ID", () {
      // Arrange
      RouteType tram;
      int tramId = 1;

      // Act
      tram = RouteType.withId(id: tramId);
      RouteTypeEnum result = tram.type;

      //Assert
      expect(result, equals(RouteTypeEnum.tram));
    });

    test("Initialising tram via Name", () {
      // Arrange
      RouteType tram;
      String tramName = "tram";

      // Act
      tram = RouteType.withName(name: tramName);
      RouteTypeEnum result = tram.type;

      //Assert
      expect(result, equals(RouteTypeEnum.tram));
    });
  });

  // Bus
  group("Bus Initialisation", () {
    test("Initialising bus via ID", () {
      // Arrange
      RouteType bus;
      int busId = 2;

      // Act
      bus = RouteType.withId(id: busId);
      RouteTypeEnum result = bus.type;

      //Assert
      expect(result, equals(RouteTypeEnum.bus));
    });

    test("Initialising vLine via Name", () {
      // Arrange
      RouteType vLine;
      String busName = "bus";

      // Act
      vLine = RouteType.withName(name: busName);
      RouteTypeEnum result = vLine.type;

      //Assert
      expect(result, equals(RouteTypeEnum.bus));
    });
  });

  // vLine
  group("vLine Initialisation", () {
    test("Initialising vLine via ID", () {
      // Arrange
      RouteType vLine;
      int vLineId = 3;

      // Act
      vLine = RouteType.withId(id: vLineId);
      RouteTypeEnum result = vLine.type;

      //Assert
      expect(result, equals(RouteTypeEnum.vLine));
    });

    test("Initialising vLine via Name", () {
      // Arrange
      RouteType vLine;
      String vLineName = "vLine";

      // Act
      vLine = RouteType.withName(name: vLineName);
      RouteTypeEnum result = vLine.type;

      //Assert
      expect(result, equals(RouteTypeEnum.vLine));
    });
  });

  // Name Normalisation
  group("Name Normalisation", () {
    test("Uppercase", () {
      String name = "TRAM";
      expect(RouteType.withName(name: name).type, RouteTypeEnum.tram);

      name = "tRAm";
      expect(RouteType.withName(name: name).type, RouteTypeEnum.tram);
    });

    test("Spaces", () {
      String name = "t r a m";
      expect(RouteType.withName(name: name).type, RouteTypeEnum.tram);

      name = "tram ";
      expect(RouteType.withName(name: name).type, RouteTypeEnum.tram);

      name = "     tram ";
      expect(RouteType.withName(name: name).type, RouteTypeEnum.tram);
    });
  });

  // Non-Initialisation
  group("Invalid Initialisation", () {
    test("Initialising via ID", () {
      // Arrange
      int id = -2;

      // Act & Assert
      expect( () => RouteType.withId(id: id), throwsArgumentError);
    });

    test("Initialising via Name", () {
      // Arrange
      String name = "busz";

      // Act & Assert
      expect( () => RouteType.withName(name: name), throwsArgumentError);
    });
  });
}
