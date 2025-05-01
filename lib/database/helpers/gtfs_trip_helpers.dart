import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GtfsTripHelpers on AppDatabase {
  Future<GtfsTripsTableCompanion> createGtfsTripCompanion({required String tripId, required String routeId, required String tripHeadsign, required int wheelchairAccessible})
  async {
    return GtfsTripsTableCompanion(
      tripId: drift.Value(tripId),
      routeId: drift.Value(routeId),
      tripHeadsign: drift.Value(tripHeadsign),
      wheelchairAccessible: drift.Value(wheelchairAccessible),
    );
  }

  Future<void> addGtfsTrip({required String tripId, required String routeId, required String tripHeadsign, required int wheelchairAccessible}) async {
    GtfsTripsTableCompanion trip = await createGtfsTripCompanion(tripId: tripId, routeId: routeId, tripHeadsign: tripHeadsign, wheelchairAccessible: wheelchairAccessible);
    await insertGtfsTrip(trip);
  }
}