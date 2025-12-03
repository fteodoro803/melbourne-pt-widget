import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';
import 'package:flutter_project/database/helpers/database_helpers.dart';

part 'gtfs_assets_dao.g.dart';

@DriftAccessor(tables: [GtfsAssetsTable])
class GtfsAssetsDao extends DatabaseAccessor<Database>
    with _$GtfsAssetsDaoMixin {
  GtfsAssetsDao(super.db);

  GtfsAssetsTableCompanion createGtfsAssetCompanion(
      {required String id, required DateTime dateModified}) {
    return GtfsAssetsTableCompanion(
      id: Value(id),
      version: Value(dateModified),
      versionReadable: Value(dateModified.toString()),
    );
  }

  /// Adds/Updates a GTFS Asset to the database.
  Future<void> addGtfsAsset(GtfsAssetsTableCompanion asset) async {
    await db.mergeUpdate(
        gtfsAssetsTable, asset, (a) => a.id.equals(asset.id.value));
  }

  /// Returns the DateTime of the date when the asset was last modified.
  Future<DateTime?> getGtfsAssetDate({required String id}) async {
    // 1. Filter by asset name
    var query = select(gtfsAssetsTable)..where((tbl) => tbl.id.equals(id));
    var result = await query.getSingleOrNull();

    return result?.version;
  }

}