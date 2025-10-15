import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GtfsAssetsHelpers on AppDatabase {
  GtfsAssetsTableCompanion createGtfsAssetCompanion(
      {required String id, required DateTime dateModified}) {
    return GtfsAssetsTableCompanion(
      id: drift.Value(id),
      dateModified: drift.Value(dateModified),
      dateModifiedReadable: drift.Value(dateModified.toString()),
    );
  }

  Future<void> addGtfsAsset(
      {required String id, required DateTime dateModified}) async {
    GtfsAssetsTableCompanion asset =
        createGtfsAssetCompanion(id: id, dateModified: dateModified);
    await insertGtfsAsset(asset);
  }

  /// Returns the DateTime of the date when the asset was last modified.
  Future<DateTime?> getGtfsAssetDate({required String id}) async {
    // 1. Filter by asset name
    var query = select(gtfsAssetsTable)..where((tbl) => tbl.id.equals(id));
    var result = await query.getSingleOrNull();

    return result?.dateModified;
  }
}
