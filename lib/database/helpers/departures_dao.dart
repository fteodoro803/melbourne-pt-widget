import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'departures_dao.g.dart';

@DriftAccessor(tables: [DeparturesTable])
class DeparturesDao extends DatabaseAccessor<Database>
    with _$DeparturesDaoMixin {
  DeparturesDao(super.db);

  DeparturesTableCompanion createDepartureCompanion(
      {required String runRef,
        required int stopId,
        required int routeId,
        required int directionId,
        DateTime? scheduledDepartureUTC,
        DateTime? estimatedDepartureUTC,
        bool? hasLowFloor,
        bool? hasAirConditioning}) {
    String? scheduledDeparture = getTime(scheduledDepartureUTC);
    String? estimatedDeparture = getTime(estimatedDepartureUTC);

    return DeparturesTableCompanion(
      runRef: Value(runRef),
      stopId: Value(stopId),
      routeId: Value(routeId),
      directionId: Value(directionId),
      scheduledDepartureUtc: Value(scheduledDepartureUTC),
      estimatedDepartureUtc: Value(estimatedDepartureUTC),
      scheduledDeparture: Value(scheduledDeparture),
      estimatedDeparture: Value(estimatedDeparture),
      hasLowFloor:
      hasLowFloor != null ? Value(hasLowFloor) : Value.absent(),
      hasAirConditioning: hasAirConditioning != null
          ? Value(hasAirConditioning)
          : Value.absent(),
      lastUpdated: Value(DateTime.now()),
    );
  }

  /// Adds departure to the database.
  /// Upserts if the departure if it already exists.
  Future<void> addDeparture(DeparturesTableCompanion departure) async {
    await db.mergeUpdate(
      departuresTable,
      departure,
          (d) =>
      d.runRef.equals(departure.runRef.value) &
      d.stopId.equals(departure.stopId.value) &
      d.routeId.equals(departure.routeId.value) &
      d.directionId.equals(departure.directionId.value),
    );
  }

  /// Returns a more readable time string from a UTC DateTime object,
  /// localised to Melbourne time.
  /// For example, 2025-04-01T05:11:00.000Z becomes 04:11pm
  String? getTime(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }

    // Conversion to Melbourne Time
    DateTime time = dateTime.toLocal();

    // Converts from 24-hour to 12-hour time
    String hour;
    String minute = time.minute.toString();
    String meridiem;

    if (time.hour > 12) {
      hour = (time.hour - 12).toString();
      meridiem = "pm";
    } else if (time.hour == 12) {
      hour = "12";
      meridiem = "pm";
    } else if (time.hour == 0) {
      hour = "12";
      meridiem = "am";
    } else {
      hour = time.hour.toString();
      meridiem = "am";
    }

    // Adds a '0' to the left, if hour is a single digit (ex: 7 becomes 07)
    hour = hour.padLeft(2, "0");
    minute = minute.padLeft(2, "0");

    return "$hour:$minute$meridiem";
  }

// todo: add vehicle descriptors

}