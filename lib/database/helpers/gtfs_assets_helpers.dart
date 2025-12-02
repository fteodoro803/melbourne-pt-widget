import 'package:drift/drift.dart' as drift;
import 'package:flutter_project/database/database.dart';

extension GtfsAssetsHelpers on Database {
  GtfsAssetsTableCompanion createGtfsAssetCompanion(
      {required String id, required DateTime dateModified}) {
    return GtfsAssetsTableCompanion(
      id: drift.Value(id),
      version: drift.Value(dateModified),
      versionReadable: drift.Value(dateModified.toString()),
    );
  }

  Future<void> addGtfsAsset(
      {required String id, required DateTime version}) async {
    GtfsAssetsTableCompanion asset =
        createGtfsAssetCompanion(id: id, dateModified: version);
    await insertGtfsAsset(asset);
  }

  /// Returns the DateTime of the date when the asset was last modified.
  Future<DateTime?> getGtfsAssetDate({required String id}) async {
    // 1. Filter by asset name
    var query = select(gtfsAssetsTable)..where((tbl) => tbl.id.equals(id));
    var result = await query.getSingleOrNull();

    return result?.version;
  }
}
