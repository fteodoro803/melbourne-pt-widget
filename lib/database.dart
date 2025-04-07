import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// todo: add disruptions (it comes with Departures i think)

// todo: think about whether columns here should be nullable, because all the swagger api shows is that they are
// todo: find a way to have them delete/be replaced some time after their departure time
class Departures extends Table {
  // IntColumn get id => integer().autoIncrement()();

  // Departure Times (UTC and formatted Melbourne times)
  DateTimeColumn get scheduledDepartureUtc => dateTime().nullable()();
  DateTimeColumn get estimatedDepartureUtc => dateTime().nullable()();
  TextColumn get scheduledDeparture => text().nullable()();       // ie. 12:30pm
  TextColumn get estimatedDeparture => text().nullable()();

  // Vehicle Descriptors
  TextColumn get runRef => text().nullable()();
  BoolColumn get hasLowFloor => boolean().nullable()();
  BoolColumn get hasAirConditioning => boolean().nullable()();

  // Stop, Route, and Direction Identifiers
  IntColumn get stopId => integer().references(Stops, #id).nullable()();
  IntColumn get routeId => integer().references(Routes, #id).nullable()();
  IntColumn get directionId => integer().references(Directions, #id).nullable()();

  DateTimeColumn get lastUpdated => dateTime()();

  // todo: maybe its primary foreign key should be the runref? what if it's null?
  @override
  Set<Column> get primaryKey => {scheduledDeparture, runRef, directionId};
}

class Directions extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// todo: Patterns

class Routes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get number => integer().nullable()();     // trains don't have numbers
  TextColumn get colour => text()();
  TextColumn get textColour => text()();
  IntColumn get routeTypeId => integer().references(RouteTypes, #id)();
  TextColumn get status => text()();
  // TextColumn get routeTypeName => text().references(RouteTypes, #name)();
  // todo: add geopaths here
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class RouteTypes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withLength(min: 3, max: 10)();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Stops extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get routeTypeId => integer().references(RouteTypes, #id)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  // todo: hasShelter, hasHighPlatform    -- > currently only available for train/vLine
  // todo: zone, and inFreeTramZone (in stops along route) -- stops["stop_ticket"]["zone"] | stops["stop_ticket"]["is_free_fare_zone"]
  TextColumn get zone => text().nullable()();     // only obtainable if using stopsAlongRoutes, but not stopsNearLocation
  BoolColumn get isFreeFareZone => boolean().nullable()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// class GeoPaths extends Table {
//   IntColumn get routeId =>
// }

@DriftDatabase(tables: [Departures, Directions, RouteTypes, Routes, Stops])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());
  Duration expiry = Duration(minutes: 5);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    print("( database.dart -> _openConnection ) -- opening database");
    return driftDatabase(
      name: 'transport_database',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        // databaseDirectory: getApplicationSupportDirectory,
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }

  // Departure Functions
  /// Adds a departure to the database, if it doesn't already exist,
  /// or if it has past the "expiry" time
  Future<void> insertDeparture(DeparturesCompanion departure) async {
    // final exists = await (select(departures)
    //   ..where((d) => d.id.equals(departure.id.value))).getSingleOrNull();
    // if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
    //   into(departures).insertOnConflictUpdate(departure);
    // }
    into(departures).insertOnConflictUpdate(departure);
    // into(departures).insert(departure);
  }

  // Direction Functions
  /// Adds a direction to the database, if it doesn't already exist,
  /// or if it has past the "expiry" time
  Future<void> insertDirection(DirectionsCompanion direction) async {
    final exists = await (select(directions)
      ..where((d) => d.id.equals(direction.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      into(directions).insertOnConflictUpdate(direction);
    }
  }

  // RouteType Functions
  /// Adds a route type to the database, if it doesn't already exist,
  /// or if it has past the "expiry" time
  Future<void> insertRouteType(RouteTypesCompanion routeType) async {
    final exists = await (select(routeTypes)
      ..where((d) => d.id.equals(routeType.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      into(routeTypes).insertOnConflictUpdate(routeType);
    }
  }

  Future<String?> getRouteTypeNameFromRouteTypeId(int id) async {
    final result = await (select(routeTypes)
      ..where((routeType) => routeType.id.equals(id)))
        .getSingleOrNull();

    return result?.name;
  }

  // Route Functions
  /// Adds a route to the database, if it doesn't already exist,
  /// or if it has past the "expiry" time
  Future<void> insertRoute(RoutesCompanion route) async {
    final exists = await (select(routes)..where((d) => d.id.equals(route.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      into(routes).insertOnConflictUpdate(route);
    }
  }

  // Stop Functions
  /// Adds a stop to the database, if it doesn't already exist,
  /// or if it has past the "expiry" time
  Future<void> insertStop(StopsCompanion stop) async {
    final exists = await (select(stops)..where((d) => d.id.equals(stop.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      into(stops).insertOnConflictUpdate(stop);
    }
  }

  // Table Functions
  // Future<void> clearData() async {
  //   await delete(departures).go();
  // }
}