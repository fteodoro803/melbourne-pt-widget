import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/departure_helpers.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

void main() {
  group("mergeUpdate -", () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test("insert a new row", () async {
      // Add departure to database
      String runRef = "0";
      int stopId = 1, routeId = 2, directionId = 3;
      bool hasLowFloor = true, hasAirConditioning = true;

      final departure = db.createDepartureCompanion(
          runRef: runRef,
          stopId: stopId,
          routeId: routeId,
          directionId: directionId,
          hasAirConditioning: hasAirConditioning,
          hasLowFloor: hasLowFloor);

      await db.mergeUpdate(
        db.departuresTable,
        departure,
        (d) =>
            d.runRef.equals(departure.runRef.value) &
            d.stopId.equals(departure.stopId.value) &
            d.routeId.equals(departure.routeId.value) &
            d.directionId.equals(departure.directionId.value),
      );

      // Get departure
      final rows = await db.select(db.departuresTable).get();
      expect(rows.length, 1, reason: "New row should be added");

      SimpleSelectStatement<$DeparturesTableTable, DeparturesTableData> query;
      query = db.select(db.departuresTable)
        ..where(
          (d) =>
              d.runRef.equals(departure.runRef.value) &
              d.stopId.equals(departure.stopId.value) &
              d.routeId.equals(departure.routeId.value) &
              d.directionId.equals(departure.directionId.value),
        );

      final result = await query.getSingleOrNull();
      expect(result != null, true, reason: "New row should not be null");
    });

    test("update a row with non-null fields", () async {
      // Add departure to database
      String runRef = "0";
      int stopId = 1, routeId = 2, directionId = 3;
      bool hasLowFloor = true, hasAirConditioning = true;

      // 1. Add initial departure to database
      final departure = db.createDepartureCompanion(
        runRef: runRef,
        stopId: stopId,
        routeId: routeId,
        directionId: directionId,
        hasLowFloor: hasLowFloor,
        hasAirConditioning: hasAirConditioning,
      );

      await db.mergeUpdate(
        db.departuresTable,
        departure,
        (d) =>
            d.runRef.equals(departure.runRef.value) &
            d.stopId.equals(departure.stopId.value) &
            d.routeId.equals(departure.routeId.value) &
            d.directionId.equals(departure.directionId.value),
      );

      // 2. Update departure
      String updatedRunRef = "1";
      bool updatedHasLowFloor = false;
      final updatedDeparture = db.createDepartureCompanion(
        runRef: updatedRunRef,
        stopId: stopId,
        routeId: routeId,
        directionId: directionId,
        hasLowFloor: updatedHasLowFloor,
        hasAirConditioning: hasAirConditioning,
      );

      await db.mergeUpdate(
        db.departuresTable,
        updatedDeparture,
        (d) =>
            d.runRef.equals(departure.runRef.value) &
            d.stopId.equals(departure.stopId.value) &
            d.routeId.equals(departure.routeId.value) &
            d.directionId.equals(departure.directionId.value),
      );

      // Compare
      SimpleSelectStatement<$DeparturesTableTable, DeparturesTableData> query;
      query = db.select(db.departuresTable)
        ..where(
          (d) =>
              // d.runRef.equals(departure.runRef.value) &
              d.stopId.equals(departure.stopId.value) &
              d.routeId.equals(departure.routeId.value) &
              d.directionId.equals(departure.directionId.value),
        );
      final result = await query.getSingleOrNull();

      expect(result!.runRef, updatedRunRef,
          reason: "Non-nullable field should be updated");
      expect(result.hasLowFloor, updatedHasLowFloor,
          reason: "Nullable field should be updated");
    });

    test("update a row's updatable fields", () async {
      // Add departure to database
      String runRef = "0";
      int stopId = 1, routeId = 2, directionId = 3;
      bool? hasLowFloor = true, hasAirConditioning = true;

      // 1. Add initial departure to database
      final departure = db.createDepartureCompanion(
        runRef: runRef,
        stopId: stopId,
        routeId: routeId,
        directionId: directionId,
        hasLowFloor: hasLowFloor,
        hasAirConditioning: hasAirConditioning,
      );

      await db.mergeUpdate(
        db.departuresTable,
        departure,
        (d) =>
            d.runRef.equals(departure.runRef.value) &
            d.stopId.equals(departure.stopId.value) &
            d.routeId.equals(departure.routeId.value) &
            d.directionId.equals(departure.directionId.value),
      );

      // 2. Update departure
      bool? updatedHasLowFloor = null, updatedHasAirConditioning = false;
      final updatedDeparture = db.createDepartureCompanion(
        runRef: runRef,
        stopId: stopId,
        routeId: routeId,
        directionId: directionId,
        hasLowFloor: updatedHasLowFloor,
        hasAirConditioning: updatedHasAirConditioning,
      );

      await db.mergeUpdate(
        db.departuresTable,
        updatedDeparture,
        (d) =>
            d.runRef.equals(departure.runRef.value) &
            d.stopId.equals(departure.stopId.value) &
            d.routeId.equals(departure.routeId.value) &
            d.directionId.equals(departure.directionId.value),
      );

      // Compare
      SimpleSelectStatement<$DeparturesTableTable, DeparturesTableData> query;
      query = db.select(db.departuresTable)
        ..where(
          (d) =>
              d.runRef.equals(departure.runRef.value) &
              d.stopId.equals(departure.stopId.value) &
              d.routeId.equals(departure.routeId.value) &
              d.directionId.equals(departure.directionId.value),
        );
      final result = await query.getSingleOrNull();

      expect(result!.hasLowFloor, hasLowFloor,
          reason: "Updatable field shouldn't change due to new absent value");
      expect(result.hasAirConditioning, updatedHasAirConditioning,
          reason: "Updatable field should change due to new non-null value");
    });

    test("update a row's overwrite fields", () async {
      // Add departure to database
      String runRef = "0";
      int stopId = 1, routeId = 2, directionId = 3;
      DateTime? scheduledDeparture = DateTime(1),
          estimatedDeparture = DateTime(2);

      // 1. Add initial departure to database
      final departure = db.createDepartureCompanion(
        runRef: runRef,
        stopId: stopId,
        routeId: routeId,
        directionId: directionId,
        scheduledDepartureUTC: scheduledDeparture,
        estimatedDepartureUTC: estimatedDeparture,
      );

      await db.mergeUpdate(
        db.departuresTable,
        departure,
        (d) =>
            d.runRef.equals(departure.runRef.value) &
            d.stopId.equals(departure.stopId.value) &
            d.routeId.equals(departure.routeId.value) &
            d.directionId.equals(departure.directionId.value),
      );

      // 2. Update departure
      DateTime? updatedEstimatedDeparture = null,
          updatedScheduledDeparture = DateTime(3);
      final updatedDeparture = db.createDepartureCompanion(
        runRef: runRef,
        stopId: stopId,
        routeId: routeId,
        directionId: directionId,
        scheduledDepartureUTC: updatedScheduledDeparture,
        estimatedDepartureUTC: updatedEstimatedDeparture,
      );

      await db.mergeUpdate(
        db.departuresTable,
        updatedDeparture,
        (d) =>
            d.runRef.equals(departure.runRef.value) &
            d.stopId.equals(departure.stopId.value) &
            d.routeId.equals(departure.routeId.value) &
            d.directionId.equals(departure.directionId.value),
      );

      // Compare
      SimpleSelectStatement<$DeparturesTableTable, DeparturesTableData> query;
      query = db.select(db.departuresTable)
        ..where(
          (d) =>
              d.runRef.equals(departure.runRef.value) &
              d.stopId.equals(departure.stopId.value) &
              d.routeId.equals(departure.routeId.value) &
              d.directionId.equals(departure.directionId.value),
        );
      final result = await query.getSingleOrNull();

      expect(result!.scheduledDepartureUtc, updatedScheduledDeparture,
          reason: "Overwrite field should change to new non-null value");
      expect(result.estimatedDepartureUtc, updatedEstimatedDeparture,
          reason: "Overwrite field should change to new null value");
    });
  });
}
