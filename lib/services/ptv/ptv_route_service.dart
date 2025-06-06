import 'package:flutter_project/api_data.dart';
import 'package:flutter_project/database/database.dart' as db;
import 'package:flutter_project/database/helpers/link_route_stops_helpers.dart';
import 'package:flutter_project/database/helpers/route_helpers.dart';
import 'package:flutter_project/domain/route.dart';
import 'package:flutter_project/domain/route_type.dart';
import 'package:flutter_project/services/ptv/ptv_base_service.dart';

class PtvRouteService extends PtvBaseService {
  // Route Functions
  /// Fetches all routes offered by PTV from the database.
  /// If no route data is in database, it fetches from the PTV API and stores it to database.
  Future<List<Route>> fetchRoutes({String? routeTypes}) async {
    List<Route> routeList = [];

    // 1a. Checks if data exists in database, and sets routeList if it exists
    int? routeType = routeTypes != null ? int.tryParse(routeTypes) : null;
    final dbRouteList = await database.getRoutes(routeType);
    if (dbRouteList.isNotEmpty) {
      routeList = dbRouteList.map(Route.fromDb).toList();
    }

    // 1b. Fetches data from API and adds to database, if route data doesn't exist in database
    else {
      // Fetches stop data via PTV API
      ApiData data = await apiService.routes(routeTypes: routeTypes);
      Map<String, dynamic>? jsonResponse = data.response;

      // Empty JSON Response
      if (jsonResponse == null) {
        handleNullResponse("fetchRoutes");
        return [];
      }

      // 2. Creates new routes, and adds them to return list and database
      for (var route in jsonResponse["routes"]) {
        Route newRoute = Route.fromApi(route);
        routeList.add(newRoute);

        // 3. Add to Database
        await database.addRoute(
            newRoute.id, newRoute.name, newRoute.number, newRoute.type.id,
            newRoute.gtfsId, newRoute.status);
      }
    }

    return routeList;
  }

  /// Fetches routes from database, by search name.
  Future<List<Route>> searchRoutes({String? query, RouteType? routeType}) async {
    final dbRouteList = await database.getRoutesByName(search: query, routeType: routeType?.id);
    List<Route> domainRouteList = dbRouteList.map(Route.fromDb).toList();
    return domainRouteList;
  }

  /// Fetches routes from database, by id.
  Future<Route?> getRouteById({required int id, bool withDetails = false}) async {
    // 1. Get route from database
    final dbRoute = await database.getRouteById(id);
    Route? route = dbRoute != null ? Route.fromDb(dbRoute) : null;

    // 2. Lazy load route details
    if (withDetails == true && route != null) await route.loadDetails();

    return route;
  }

  /// Fetches routes according to a stop, from the database.
  /// Maps the databases' routes to domain's route
  // todo: consider change this to getRoutesFromStop, or something like that. Fetch is reserved for functions with API calls
  // todo: but also, in our functions, we use fetch, but most of them also check the database first. So maybe for consistency, keep it?
  Future<List<Route>> fetchRoutesFromStop(int stopId) async {
    final List<db.RoutesTableData> dbRoutes = await database.getRoutesFromStop(stopId);

    // Convert Route's database model to domain model
    List<Route> routeList = dbRoutes.map(Route.fromDb).toList();

    return routeList;
  }
}