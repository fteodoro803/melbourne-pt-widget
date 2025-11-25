import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';
import 'package:get/get.dart';

extension DepartureHelpers on Database {
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
      runRef: drift.Value(runRef),
      stopId: drift.Value(stopId),
      routeId: drift.Value(routeId),
      directionId: drift.Value(directionId),
      scheduledDepartureUtc: drift.Value(scheduledDepartureUTC),
      estimatedDepartureUtc: drift.Value(estimatedDepartureUTC),
      scheduledDeparture: drift.Value(scheduledDeparture),
      estimatedDeparture: drift.Value(estimatedDeparture),
      hasLowFloor:
          hasLowFloor != null ? drift.Value(hasLowFloor) : drift.Value.absent(),
      hasAirConditioning: hasAirConditioning != null
          ? drift.Value(hasAirConditioning)
          : drift.Value.absent(),
      lastUpdated: drift.Value(DateTime.now()),
    );
  }

  // todo: maybe i can just make this take a Departure instance, bc there are so many arguments. Check how to make a departure table a class.
  Future<void> addDeparture(
      {required String runRef,
      required int stopId,
      required int routeId,
      required int directionId,
      DateTime? scheduledDepartureUTC,
      DateTime? estimatedDepartureUTC,
      bool? hasLowFloor,
      bool? hasAirConditioning}) async {
    DeparturesTableCompanion departure = createDepartureCompanion(
        scheduledDepartureUTC: scheduledDepartureUTC,
        estimatedDepartureUTC: estimatedDepartureUTC,
        runRef: runRef,
        stopId: stopId,
        directionId: directionId,
        routeId: routeId,
        hasAirConditioning: hasAirConditioning,
        hasLowFloor: hasLowFloor);
    Database db = Get.find<Database>();
    await db.insertDeparture(departure);
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
