import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GtfsTripHelpers on AppDatabase {
  GtfsTripsTableCompanion createGtfsTripCompanion({required String tripId, required String routeId, required String tripHeadsign, required int wheelchairAccessible}) {
    return GtfsTripsTableCompanion(
      tripId: drift.Value(tripId),
      routeId: drift.Value(routeId),
      tripHeadsign: drift.Value(tripHeadsign),
      wheelchairAccessible: drift.Value(wheelchairAccessible),
    );
  }

  Future<void> addGtfsTrip({required String tripId, required String routeId, required String tripHeadsign, required int wheelchairAccessible}) async {
    GtfsTripsTableCompanion trip = createGtfsTripCompanion(tripId: tripId, routeId: routeId, tripHeadsign: tripHeadsign, wheelchairAccessible: wheelchairAccessible);
    await insertGtfsTrip(trip);
  }

  Future<void> addGtfsTrips({required List<GtfsTripsTableCompanion> trips}) async {
    await batchInsert(gtfsTripsTable, trips);
  }
}