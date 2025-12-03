import 'package:flutter_project/database/database.dart' as db;
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
    final dbRouteList = await database.routesDao.getRoutes(routeType);
    if (dbRouteList.isNotEmpty) {
      // routeList = dbRouteList.map(Route.fromDb).toList();

      for (int i = 0; i < dbRouteList.length; i++) {
        Route? newRoute = await Route.fromDbAsync(dbRouteList[i]);
        if (newRoute != null) {
          routeList.add(newRoute);
        }
      }
    }

    // 1b. Fetches data from API and adds to database, if route data doesn't exist in database
    else {
      // Fetches stop data via PTV API
      var data = await apiService.routes(routeTypes: routeTypes);

      // Empty JSON Response
      if (data == null) {
        handleNullResponse("fetchRoutes");
        return [];
      }

      // 2. Creates new routes, and adds them to return list and database
      for (var route in data["routes"]) {
        Route newRoute = Route.fromApi(route);
        routeList.add(newRoute);

        // 3. Add to Database
        await database.routesDao.addRoute(
            id: newRoute.id,
            name: newRoute.name,
            number: newRoute.number,
            routeTypeId: newRoute.type.id,
            status: newRoute.status);
      }
    }

    return routeList;
  }

  /// Fetches routes from database, by search name.
  Future<List<Route>> searchRoutes(
      {String? query, RouteType? routeType}) async {
    final dbRouteList =
        await database.routesDao.getRoutesByName(search: query, routeType: routeType?.id);
    // List<Route> domainRouteList = dbRouteList.map(Route.fromDb).toList();

    List<Route> domainRouteList = [];
    for (int i = 0; i < dbRouteList.length; i++) {
      Route? newRoute = await Route.fromDbAsync(dbRouteList[i]);
      if (newRoute != null) domainRouteList.add(newRoute);
    }

    return domainRouteList;
  }

  /// Fetches routes from database, by id.
  Future<Route?> getRouteById(
      {required int id, bool withDetails = false}) async {
    // 1. Get route from database
    final dbRoute = await database.routesDao.getRouteById(id);
    Route? route = dbRoute != null ? await Route.fromDbAsync(dbRoute) : null;

    // 2. Lazy load route details
    if (withDetails == true && route != null) await route.loadDetails();

    return route;
  }

  /// Fetches routes according to a stop, from the database.
  /// Maps the databases' routes to domain's route
  // todo: consider change this to getRoutesFromStop, or something like that. Fetch is reserved for functions with API calls
  // todo: but also, in our functions, we use fetch, but most of them also check the database first. So maybe for consistency, keep it?
  Future<List<Route>> fetchRoutesFromStop(int stopId) async {
    final List<db.RoutesTableData> dbRoutes =
        await database.linkRouteStopsDao.getRoutesFromStop(stopId);

    // Convert Route's database model to domain model
    // List<Route> routeList = dbRoutes.map(Route.fromDb).toList();

    List<Route> routeList = [];
    for (int i = 0; i < dbRoutes.length; i++) {
      Route? newRoute = await Route.fromDbAsync(dbRoutes[i]);
      if (newRoute != null) routeList.add(newRoute);
    }

    return routeList;
  }
}
