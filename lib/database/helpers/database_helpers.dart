import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter_project/database/database.dart';

extension StopRouteDirectionHelpers on Database {
  /// Generic method to merge and update records.
  /// Only updates fields that are present in the new data.
  Future<void> mergeUpdate<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> newData,
    Expression<bool> Function(T) whereClause,
  ) async {
    final query = select(table)..where(whereClause);
    final existing = await query.getSingleOrNull();

    if (existing == null) {
      await into(table).insertOnConflictUpdate(newData);
    } else {
      await (update(table)..where(whereClause)).write(newData);
    }
  }

  /// Generic method to batch insert a list of entries to a table.
  // todo: find a way to add mergeUpdate here
  Future<void> batchInsert<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, List<Insertable<D>> entries,
      {int batchSize = 150}) async {
    // Process batches in chunks
    for (int i = 0; i < entries.length; i += batchSize) {
      // If current index plus batchSize is less than total entries, the final/end index for this current batch is the current largest
      int end = min((i + batchSize), entries.length);
      var currBatch = entries.sublist(i, end);

      await batch((b) {
        b.insertAllOnConflictUpdate(table, currBatch);
      });
    }
  }
}
