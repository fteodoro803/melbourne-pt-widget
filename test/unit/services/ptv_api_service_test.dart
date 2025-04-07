import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/api/ptv_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../../mocks/mock_global_configuration.mocks.dart';
import '../../mocks/ptv_responses.dart';

@GenerateMocks([http.Client])
import 'ptv_api_service_test.mocks.dart';

void main() {
  late PtvApiService service;
  late MockGlobalConfiguration mockConfig;
  late MockClient mockClient;
  late PtvResponses ptvResponses;

  setUp(() {
    ptvResponses = PtvResponses();
    mockConfig = MockGlobalConfiguration();
    when(mockConfig.get("ptvUserId")).thenReturn("testUser");
    when(mockConfig.get("ptvApiKey")).thenReturn("testApiKey");
    mockClient = MockClient();

    service = PtvApiService(config: mockConfig, client: mockClient); // Instantiate your class if it's a method within a class
  });

  test("ptv_api_service initialisation", () {
    expect(service.userId, "testUser");
    expect(service.apiKey, "testApiKey");
  });

  // todo: figure out mockito
  // group("routeTypes()", () {
  //   test("should return correct ApiData", () async {
  //     // Setup mock response
  //     String response = ptvResponses.routeTypesResponse;
  //     when(mockClient.get(any)).thenAnswer((_) async =>
  //       http.Response(response, 200));
  //
  //     final result = await service.routeTypes();
  //
  //     expect(result.response?["route_types"][0]["route_type_name"], "Train");
  //   });
  // });

  group('_handleParameters', () {
    test('should return an empty map when all parameters are null', () {
      final result = service.handleParameters(
        routeTypes: null,
        maxResults: null,
        maxDistance: null,
        directionId: null,
        geoPath: null,
        expand: null,
      );
      expect(result, isEmpty);
    });

    test('should return an empty map when all parameters are empty', () {
      final result = service.handleParameters();
      expect(result, isEmpty);
    });

    test('should include route_types when routeTypes is not empty', () {
      final result = service.handleParameters(routeTypes: "1,2,3");
      expect(result, containsPair('route_types', ['1', '2', '3']));
    });

    test('should include max_results when maxResults is not empty', () {
      final result = service.handleParameters(maxResults: "10");
      expect(result, containsPair('max_results', "10"));
    });

    test('should include max_distance when maxDistance is not empty', () {
      final result = service.handleParameters(maxDistance: "500");
      expect(result, containsPair('max_distance', "500"));
    });

    test('should include direction_id when directionId is not empty', () {
      final result = service.handleParameters(directionId: "1");
      expect(result, containsPair('direction_id', "1"));
    });

    test('should include include_geopath when geoPath is true', () {
      final result = service.handleParameters(geoPath: true);
      expect(result, containsPair('include_geopath', "true"));
    });

    test('should not include include_geopath when geoPath is false', () {
      final result = service.handleParameters(geoPath: false);
      expect(result, isNot(contains('include_geopath')));
    });

    test('should include expand as a list when expand is not empty', () {
      final result = service.handleParameters(expand: "Stops,Routes");
      expect(result, containsPair('expand', ['Stops', 'Routes']));
    });

    test('should handle multiple parameters correctly', () {
      final result = service.handleParameters(
        routeTypes: "1,2",
        maxResults: "5",
        directionId: "0",
        geoPath: true,
        expand: "All",
      );
      expect(result, containsPair('route_types', ['1', '2']));
      expect(result, containsPair('max_results', "5"));
      expect(result, containsPair('direction_id', "0"));
      expect(result, containsPair('include_geopath', "true"));
      expect(result, containsPair('expand', ['All']));
    });

    test('should not include parameters with empty string values', () {
      final result = service.handleParameters(
        routeTypes: "",
        maxResults: "",
        maxDistance: "",
        directionId: "",
        expand: "",
      );
      expect(result, isEmpty);
    });
  });
}