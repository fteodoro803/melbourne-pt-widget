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

class RouteTypes extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withLength(min: 3, max: 10)();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Directions, RouteTypes])
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

  /// Adds a direction to the database, if it doesn't already exist,
  /// or if it has past the "expiry" time
  Future<void> insertDirection(DirectionsCompanion direction) async {
    final exists = await (select(directions)..where((d) => d.id.equals(direction.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      into(directions).insertOnConflictUpdate(direction);
    }
  }

  /// Adds a route type to the database, if it doesn't already exist,
  /// or if it has past the "expiry" time
  Future<void> insertRouteType(RouteTypesCompanion routeType) async {
    final exists = await (select(routeTypes)..where((d) => d.id.equals(routeType.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      into(routeTypes).insertOnConflictUpdate(routeType);
    }
  }
}