import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Directions extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Routes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get number => integer().nullable()();
  TextColumn get colour => text().nullable()();        // todo: make this non nullable
  TextColumn get textColour => text().nullable()();    // todo: make this non nullable
  IntColumn get routeTypeId => integer().references(RouteTypes, #id)();
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
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// class GeoPaths extends Table {
//   IntColumn get routeId =>
// }

@DriftDatabase(tables: [Directions, RouteTypes, Routes, Stops])
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
}