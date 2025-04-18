import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// todo: add transport

// todo: add disruptions (it comes with Departures i think)

// todo: think about whether columns here should be nullable, because all the swagger api shows is that they are
// todo: find a way to have them delete/be replaced some time after their departure time
class DeparturesTable extends Table {
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
  IntColumn get stopId => integer().references(StopsTable, #id).nullable()();
  IntColumn get routeId => integer().references(RoutesTable, #id).nullable()();
  IntColumn get directionId => integer().references(DirectionsTable, #id).nullable()();

  // todo: Column for Transport mapping? Because each Departure is mapped to a Transport
  // todo: Add Column for Platform Number
  IntColumn get platform =>

  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  // todo: maybe its primary foreign key should be the runref? what if it's null?
  @override
  Set<Column> get primaryKey => {runRef, stopId, routeId, directionId};
}

class DirectionsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get routeId => integer().references(RoutesTable, #id)();
  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// todo: Patterns

class RoutesTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get number => text()();                    // todo: convert this to int?
  IntColumn get routeTypeId => integer().references(RouteTypesTable, #id)();
  TextColumn get gtfsId => text()();
  TextColumn get status => text()();
  // todo: add geopaths here
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class RouteTypesTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withLength(min: 3, max: 10)();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StopsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get sequence => integer().nullable()();
  // todo: hasShelter, hasHighPlatform    -- > currently only available for train/vLine
  // todo: zone, and inFreeTramZone (in stops along route) -- stops["stop_ticket"]["zone"] | stops["stop_ticket"]["is_free_fare_zone"]
  TextColumn get zone => text().nullable()();     // only obtainable if using stopsAlongRoutes, but not stopsNearLocation
  BoolColumn get isFreeFareZone => boolean().nullable()();

  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransportsTable extends Table {
  TextColumn get uniqueId => text()();
  IntColumn get routeTypeId => integer()();
  IntColumn get routeId => integer()();
  IntColumn get stopId => integer()();
  IntColumn get directionId => integer()();
  IntColumn get index => integer().nullable()();

  @override
  Set<Column> get primaryKey => {uniqueId};
}

// Linking Tables
/// Represents the many-to-many relationship between Stops and Routes.
/// One stop can serve multiple routes, and one route can have multiple stops.
class RouteStopsTable extends Table {
  IntColumn get routeId => integer().references(RoutesTable, #id)();
  IntColumn get stopId => integer().references(StopsTable, #id)();
  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {routeId, stopId};
}

/// Represents the many-to-many relationship between Stops and Route Types.
/// One stop can serve trams and buses, and one route type can go to multiple stops.
class StopRouteTypesTable extends Table {
  IntColumn get stopId => integer().references(StopsTable, #id)();
  IntColumn get routeTypeId => integer().references(RouteTypesTable, #id)();
  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {stopId, routeTypeId};
}

// class GeoPaths extends Table {
//   IntColumn get routeId =>
// }

@DriftDatabase(tables: [DeparturesTable, DirectionsTable, RouteTypesTable, RoutesTable, StopsTable, TransportsTable, RouteStopsTable, StopRouteTypesTable])
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

  // todo: move these functions to their respective helpers maybe?
  // todo: rethink about how insertOnConflictUpdate works, because it completely overwrites previous data with new ones
      // if the previous data was Stop(1, tram, null), and the new one is Stop(1, null, something), the result will be (1, null something) rather than Stop(1, tram, something)
      // Maybe think of where merging data could be useful? Departures? Stops? etc
      // Maybe if the data is past a long expiry, it can completely overwrite (bc maybe stops would have changed its location, but not id)
      // But within a short expiry, that's unlikely, so just update the incomplete fields?

  // Departure Functions
  /// Adds a departure to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> insertDeparture(DeparturesTableCompanion departure) async {
    // final exists = await (select(departures)
    //   ..where((d) => d.id.equals(departure.id.value))).getSingleOrNull();
    // if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
    //   await into(departures).insertOnConflictUpdate(departure);
    // }
    await into(departuresTable).insertOnConflictUpdate(departure);
    // await into(departures).insert(departure);
  }

  // Direction Functions
  /// Adds a direction to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> insertDirection(DirectionsTableCompanion direction) async {
    final exists = await (select(directionsTable)
      ..where((d) => d.id.equals(direction.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      await into(directionsTable).insertOnConflictUpdate(direction);
    }
  }

  // RouteType Functions
  /// Adds a route type to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> insertRouteType(RouteTypesTableCompanion routeType) async {
    final exists = await (select(routeTypesTable)
      ..where((d) => d.id.equals(routeType.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      await into(routeTypesTable).insertOnConflictUpdate(routeType);
    }
  }

  Future<String?> getRouteTypeNameFromRouteTypeId(int id) async {
    final result = await (select(routeTypesTable)
      ..where((routeType) => routeType.id.equals(id)))
        .getSingleOrNull();

    return result?.name;
  }

  // Route Functions
  /// Adds a route to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> insertRoute(RoutesTableCompanion route) async {
    final exists = await (select(routesTable)..where((d) => d.id.equals(route.id.value))).getSingleOrNull();
    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      await into(routesTable).insertOnConflictUpdate(route);
    }
  }

  // Stop Functions
  /// Adds a stop to the database, if it doesn't already exist.
  /// If it does, update the old stop by merging it with the new one.
  Future<void> insertStop(StopsTableCompanion stop) async {
    await mergeUpdate(stopsTable, stop, (t) => t.id.equals(stop.id.value));
  }

  // Transport Functions
  Future<void> insertTransport(TransportsTableCompanion transport) async {
    await mergeUpdate(transportsTable, transport, (t) => t.uniqueId.equals(transport.uniqueId.value));
  }

  // RouteStops Functions
  Future<void> insertRouteStopLink(RouteStopsTableCompanion routeStop) async {
    final exists = await (select(routeStopsTable)
      ..where((l) =>
      l.routeId.equals(routeStop.routeId.value) &
      l.stopId.equals(routeStop.stopId.value))
    ).getSingleOrNull();

    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      await into(routeStopsTable).insertOnConflictUpdate(routeStop);
    }
  }

  // StopRouteTypes Functions
  Future<void> insertStopRouteTypeLink(StopRouteTypesTableCompanion stopRouteType) async {
    final exists = await (select(stopRouteTypesTable)
      ..where((l) =>
      l.stopId.equals(stopRouteType.stopId.value) &
      l.routeTypeId.equals(stopRouteType.routeTypeId.value))
    ).getSingleOrNull();

    if (exists == null || DateTime.now().difference(exists.lastUpdated) > expiry) {
      await into(stopRouteTypesTable).insertOnConflictUpdate(stopRouteType);
    }
  }

// Table Functions
//   Future<void> clearData() async {
//     await delete(departures).go();
//   }

  /// Generic method to merge and update records.
  /// Only updates fields that are present in the new data.
  Future<void> mergeUpdate<T extends Table, D>(
      TableInfo<T, D> table,
      Insertable<D> newData,
      Expression<bool> Function(T) whereClause,
      ) async {
    final query = select(table)..where(whereClause);
    final existing = await query.getSingleOrNull();

    if (existing == null) {
      await into(table).insertOnConflictUpdate(newData);
    }
    else {
      await (update(table)..where(whereClause)).write(newData);
    }
  }
}