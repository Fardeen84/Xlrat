import '../local_database/billing_database.dart';
import '../models/job.dart';

class JobRepository {
  JobRepository(this._db);

  final BillingDatabase _db;
  static const _table = 'jobs';

  Future<Job> createJob(Job job) async {
    final db = await _db.database;
    final map = job.toMap()..remove('id');
    final id = await db.insert(_table, map);
    return job.copyWith(id: id);
  }

  Future<Job?> getJob(int id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Job.fromMap(rows.first);
  }

  Future<List<Job>> getAllJobs() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'id DESC');
    return rows.map(Job.fromMap).toList();
  }

  Future<void> updateJobStatus(int id, String status) async {
    final db = await _db.database;
    await db.update(
      _table,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteJob(int id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateJob(Job job) async {
    final db = await _db.database;
    await db.update(
      _table,
      job.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  // Generate next sequential Job Card Number: e.g. JC-YYYY-XXXX
  Future<String> generateNextJobNumber() async {
    final db = await _db.database;
    final year = DateTime.now().year;
    // Get all jobs to find the latest sequence number for the current year
    final rows = await db.query(
      _table,
      columns: ['job_number'],
      where: 'job_number LIKE ?',
      whereArgs: ['JC-$year-%'],
    );

    int maxSeq = 0;
    for (final row in rows) {
      final jobNo = row['job_number'] as String;
      final parts = jobNo.split('-');
      if (parts.length == 3) {
        final seq = int.tryParse(parts[2]) ?? 0;
        if (seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }
    final nextSeq = maxSeq + 1;
    return 'JC-$year-${nextSeq.toString().padLeft(4, '0')}';
  }
}
