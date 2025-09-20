import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// todo: add transport

// todo: add disruptions (it comes with Departures i think)

// todo: think about whether columns here should be nullable, because all the swagger api shows is that they are
// todo: find a way to have them delete/be replaced some time after their departure time

// Domain Tables
class DeparturesTable extends Table {
  // Stop, Route, and Direction Identifiers
  IntColumn get stopId => integer().references(StopsTable, #id)();
  IntColumn get routeId => integer().references(RoutesTable, #id)();
  IntColumn get directionId => integer().references(DirectionsTable, #id)();
  TextColumn get runRef => text()();

  // Departure Times (UTC and formatted Melbourne times)
  DateTimeColumn get scheduledDepartureUtc => dateTime().nullable()();    // overwrite
  DateTimeColumn get estimatedDepartureUtc => dateTime().nullable()();    // overwrite
  TextColumn get scheduledDeparture => text().nullable()();     // overwrite, ie. 12:30pm
  TextColumn get estimatedDeparture => text().nullable()();     // overwrite

  // Vehicle Descriptors
  BoolColumn get hasLowFloor => boolean().nullable()();     // updatable
  BoolColumn get hasAirConditioning => boolean().nullable()();      // updatable

  // todo: Column for Transport mapping? Because each Departure is mapped to a Transport
  // todo: Add Column for Platform Number
  // IntColumn get platform =>

  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  // todo: maybe its primary foreign key should be the runref? what if it's null?
  @override
  Set<Column> get primaryKey => {runRef, stopId, routeId, directionId};
}

// In GTFS, Direction is TripHeadsign
class DirectionsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text()();
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
  // todo: hasShelter, hasHighPlatform    -- > currently only available for train/vLine
  // todo: zone, and inFreeTramZone (in stops along route) -- stops["stop_ticket"]["zone"] | stops["stop_ticket"]["is_free_fare_zone"]
  TextColumn get zone => text().nullable()();      // updatable only obtainable if using stopsAlongRoutes, but not stopsNearLocation
  TextColumn get landmark => text().nullable()();      // updatable
  TextColumn get suburb => text().nullable()();   // todo: might not be nullable      // updatable
  BoolColumn get isFreeFareZone => boolean().nullable()();      // updatable

  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// User-Saved Tables

class TripsTable extends Table {
  TextColumn get uniqueId => text()();
  IntColumn get routeTypeId => integer()();
  IntColumn get routeId => integer()();
  IntColumn get stopId => integer()();
  IntColumn get directionId => integer()();
  IntColumn get index => integer().nullable()();      // idk what this is

  // GTFS
  TextColumn get gtfsTripId => text().nullable()();      // overwrite

  @override
  Set<Column> get primaryKey => {uniqueId};
}

// // todo: user-saved stops (one stop can have multiple trips, with different routes, but all going in the same direction)
// class UserStopsTable extends Table {
//   IntColumn get id => integer().references(StopsTable, #id)();
//   // IntColumn get direction => integer()();         // gtfs direction (0 - outbound, 1 - inbound)
// }

// Junction Tables
class LinkRouteDirectionsTable extends Table {
  IntColumn get routeId => integer().references(RoutesTable, #id)();
  IntColumn get directionId => integer().references(DirectionsTable, #id)();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {routeId, directionId};
}

/// Represents the many-to-many relationship between Stops and Routes.
/// One stop can serve multiple routes, and one route can have multiple stops.
class LinkRouteStopsTable extends Table {
  IntColumn get routeId => integer().references(RoutesTable, #id)();
  IntColumn get stopId => integer().references(StopsTable, #id)();
  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {routeId, stopId};
}

/// Represents the 3-way many-to-many relationship between [Stops], [Route], and [Directions].
/// A route goes through many stops, and each stop has a sequence.
/// A route can have multiple directions. This sequence is ordered by direction.
class LinkStopRouteDirectionsTable extends Table {
  IntColumn get stopId => integer().references(StopsTable, #id)();
  IntColumn get routeId => integer().references(RoutesTable, #id)();
  IntColumn get directionId => integer().references(DirectionsTable, #id)();
  IntColumn get sequence => integer().nullable()();      // updatable
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {stopId, routeId, directionId};
}

/// Represents the many-to-many relationship between Stops and Route Types.
/// One stop can serve trams and buses, and one route type can go to multiple stops.
class LinkStopRouteTypesTable extends Table {
  IntColumn get stopId => integer().references(StopsTable, #id)();
  IntColumn get routeTypeId => integer().references(RouteTypesTable, #id)();
  // BoolColumn get isTemporary => boolean()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {stopId, routeTypeId};
}

class GeoPathsTable extends Table {
  TextColumn get id => text()();
  IntColumn get sequence => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  @override
  Set<Column> get primaryKey => {id, sequence};
}

// Static GTFS Tables
class GtfsTripsTable extends Table {
  TextColumn get id => text()();
  TextColumn get routeId => text().references(GtfsRoutesTable, #id)();
  TextColumn get shapeId => text().references(GeoPathsTable, #id)();
  TextColumn get tripHeadsign => text()();
  IntColumn get wheelchairAccessible => integer()();
  // todo: add last Updated here, and get it from the file's last updated data

  @override
  Set<Column> get primaryKey => {id};
}

class GtfsRoutesTable extends Table {
  TextColumn get id => text()();
  TextColumn get shortName => text()();
  TextColumn get longName => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Represents the GTFS Schedule Data used in the App, and when each file was created.
/// Used to keep track of the assets, for the app's initialisation and asset updates.
class GtfsAssetsTable extends Table {
  TextColumn get id => text()();
  DateTimeColumn get dateModified => dateTime()();
  TextColumn get dateModifiedReadable => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// GTFS to PTV Route ID Mapping
class RouteMapTable extends Table {
  IntColumn get ptvId => integer().references(RoutesTable, #id)();
  TextColumn get gtfsId => text().references(GtfsRoutesTable, #id)();

  @override
  Set<Column> get primaryKey => {ptvId, gtfsId};
}


@DriftDatabase(tables: [DeparturesTable, DirectionsTable, GeoPathsTable, RouteTypesTable, RoutesTable, StopsTable, TripsTable, LinkRouteStopsTable, LinkStopRouteTypesTable, LinkRouteDirectionsTable, LinkStopRouteDirectionsTable, GtfsTripsTable, GtfsRoutesTable, GtfsAssetsTable, RouteMapTable])
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

  // Departure Functions
  /// Adds a departure to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time

  Future<void> insertDeparture(DeparturesTableCompanion departure) async {
    await mergeUpdate(departuresTable, departure, (d) =>
      d.runRef.equals(departure.runRef.value) &
      d.stopId.equals(departure.stopId.value) &
      d.routeId.equals(departure.routeId.value) &
      d.directionId.equals(departure.directionId.value),
    );
  }

  // Direction Functions
  /// Adds a direction to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> insertDirection(DirectionsTableCompanion direction) async {
    await mergeUpdate(directionsTable, direction, (d) => d.id.equals(direction.id.value));
  }

  // RouteType Functions
  /// Adds a route type to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> insertRouteType(RouteTypesTableCompanion routeType) async {
    await mergeUpdate(routeTypesTable, routeType, (r) => r.id.equals(routeType.id.value));
  }

  // Route Functions
  /// Adds a route to the database, if it doesn't already exist,
  /// or if it has passed the "expiry" time
  Future<void> insertRoute(RoutesTableCompanion route) async {
    await mergeUpdate(routesTable, route, (r) => r.id.equals(route.id.value));
  }

  // Stop Functions
  /// Adds a stop to the database, if it doesn't already exist.
  /// If it does, update the old stop by merging it with the new one.
  Future<void> insertStop(StopsTableCompanion stop) async {
    await mergeUpdate(stopsTable, stop, (t) => t.id.equals(stop.id.value));
  }

  // Transport Functions
  Future<void> insertTransport(TripsTableCompanion transport) async {
    await mergeUpdate(tripsTable, transport, (t) => t.uniqueId.equals(transport.uniqueId.value));
  }

  // LinkRouteDirections Functions
  Future<void> insertRouteDirectionLink(LinkRouteDirectionsTableCompanion routeDirection) async {
    await mergeUpdate(linkRouteDirectionsTable, routeDirection, (r) =>
        r.routeId.equals(routeDirection.routeId.value) &
        r.directionId.equals(routeDirection.directionId.value)
    );
  }

  // LinkRouteStops Functions
  Future<void> insertRouteStopLink(LinkRouteStopsTableCompanion routeStop) async {
    await mergeUpdate(linkRouteStopsTable, routeStop, (r) =>
        r.routeId.equals(routeStop.routeId.value) &
        r.stopId.equals(routeStop.stopId.value)
    );
  }

  // LinkStopRouteTypes Functions
  Future<void> insertStopRouteTypeLink(LinkStopRouteTypesTableCompanion stopRouteType) async {
    await mergeUpdate(linkStopRouteTypesTable, stopRouteType, (s) =>
      s.stopId.equals(stopRouteType.stopId.value) &
      s.routeTypeId.equals(stopRouteType.routeTypeId.value)
    );
  }

  // Link StopDirections Functions
  Future<void> insertStopRouteDirectionsLink(LinkStopRouteDirectionsTableCompanion stopDirection) async {
    await mergeUpdate(linkStopRouteDirectionsTable, stopDirection, (s) =>
        s.stopId.equals(stopDirection.stopId.value) &
        s.routeId.equals(stopDirection.routeId.value) &
        s.directionId.equals(stopDirection.directionId.value)
    );
  }

  // GTFS Route Functions
  Future<void> insertGtfsRoute(GtfsRoutesTableCompanion route) async {
    await mergeUpdate(gtfsRoutesTable, route, (r) => r.id.equals(route.id.value));
  }

  // GTFS Trip Functions
  Future<void> insertGtfsTrip(GtfsTripsTableCompanion trip) async {
    await mergeUpdate(gtfsTripsTable, trip, (t) => t.id.equals(trip.id.value));
  }

  // GTFS Asset Functions
  Future<void> insertGtfsAsset(GtfsAssetsTableCompanion asset) async {
    await mergeUpdate(gtfsAssetsTable, asset, (a) => a.id.equals(asset.id.value));
  }

  // Route Map Functions
  Future<void> insertRouteMap(RouteMapTableCompanion routeMap) async {
    await mergeUpdate(routeMapTable, routeMap, (r) => r.ptvId.equals(routeMap.ptvId.value) & r.gtfsId.equals(routeMap.gtfsId.value));
  }

  // Table Functions
  //   Future<void> clearData() async {
  //     await delete(departures).go();
  //   }

  /// Generic method to merge and update records.
  /// Only updates fields that are present in the new data.
  // todo: lots of tests on this one, and the cases where it inserts new row, updates a field, does nothing, etc
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

  /// Generic method to batch insert a list of entries to a table.
  // todo: find a way to add mergeUpdate here
  Future<void> batchInsert<T extends Table, D extends DataClass>(
      TableInfo<T, D> table,
      List<Insertable<D>> entries,
      {int batchSize = 150}
    ) async {

    // Process batches in chunks
    for (int i=0; i < entries.length; i+=batchSize) {

      // If current index plus batchSize is less than total entries, the final/end index for this current batch is the current largest
      int end = min((i+batchSize), entries.length);
      var currBatch = entries.sublist(i, end);

      await batch((b) {
        b.insertAllOnConflictUpdate(table, currBatch);
      });
    }
  }
}