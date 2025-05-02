import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GeoPathHelpers on AppDatabase {
  GeoPathsTableCompanion createGeoPathCompanion({required String id, required double latitude, required double longitude, required int sequence})
  {
    return GeoPathsTableCompanion(
      id: drift.Value(id),
      sequence: drift.Value(sequence),
      latitude: drift.Value(latitude),
      longitude: drift.Value(longitude),
    );
  }

  Future<void> addGeoPaths({required List<GeoPathsTableCompanion> geoPath}) async {
    await batchInsert(geoPathsTable, geoPath);
  }

  // todo: get geopath of a route
}