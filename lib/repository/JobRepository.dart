import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';

/// Direct Firestore repository for job cards.
class JobRepository {
  JobRepository({required this.garageId, this.onWriteError, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String garageId;
  final Function(String)? onWriteError;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('garages').doc(garageId).collection('jobs');

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<Job> createJob(Job job) async {
    try {
      final docRef = _collection.doc();
      final counterRef = _firestore
          .collection('garages')
          .doc(garageId)
          .collection('counters')
          .doc('jobs');

      DateTime jobDateTime = DateTime.now();
      try {
        jobDateTime = DateFormat('dd MMM yyyy').parse(job.date);
      } catch (_) {}
      final dateStr = DateFormat('yyyy-MM-dd').format(jobDateTime);
      final statsRef = _firestore
          .collection('garages')
          .doc(garageId)
          .collection('stats')
          .doc(dateStr);

      final toSave = await _firestore.runTransaction<Job>((transaction) async {
        // ─── ALL READS FIRST ───────────────────────────────────────────────
        final year = DateTime.now().year;
        final snap = await transaction.get(counterRef);
        final statsSnap = await transaction.get(statsRef);

        // ─── COMPUTE ────────────────────────────────────────────────────────
        int nextSeq = 1;
        if (snap.exists) {
          final data = snap.data();
          final storedYear = data?['year'] as int?;
          final currentSeq = data?['last_number'] as int?;
          if (storedYear == year && currentSeq != null) {
            nextSeq = currentSeq + 1;
          }
        }
        final nextJobNumber = 'JC-$year-${nextSeq.toString().padLeft(4, '0')}';
        final updatedJob = job.copyWith(id: docRef.id, jobNumber: nextJobNumber);

        // ─── ALL WRITES AFTER ──────────────────────────────────────────────
        transaction.set(counterRef, {
          'year': year,
          'last_number': nextSeq,
        });
        transaction.set(docRef, updatedJob.toMap());

        if (!statsSnap.exists) {
          transaction.set(statsRef, {
            'totalRevenue': 0.0,
            'invoiceCount': 0,
            'jobCount': 1,
            'pendingJobCount': updatedJob.status == 'pending' ? 1 : 0,
            'inProgressJobCount': updatedJob.status == 'in-progress' ? 1 : 0,
            'completedJobCount': updatedJob.status == 'completed' ? 1 : 0,
            'customerTotals': {},
            'partTotals': {},
          });
        } else {
          final Map<String, dynamic> statsUpdates = {
            'jobCount': FieldValue.increment(1),
          };
          if (updatedJob.status == 'pending') statsUpdates['pendingJobCount'] = FieldValue.increment(1);
          if (updatedJob.status == 'in-progress') statsUpdates['inProgressJobCount'] = FieldValue.increment(1);
          if (updatedJob.status == 'completed') statsUpdates['completedJobCount'] = FieldValue.increment(1);
          transaction.update(statsRef, statsUpdates);
        }

        return updatedJob;
      });

      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<Job?> getJob(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Job.fromMap(doc.data()!..['id'] = doc.id);
  }

  Stream<List<Job>> streamJobs({int limit = 50}) {
    return _collection
        .orderBy('job_number', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Job.fromMap(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<List<Job>> getAllJobs() async {
    final snap = await _collection.orderBy('job_number', descending: true).get();
    return snap.docs
        .map((doc) => Job.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<({List<Job> items, DocumentSnapshot? lastDoc, bool hasMore})> getJobsPaginated({
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _collection.orderBy('job_number', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.limit(limit + 1).get();
    final hasMore = snap.docs.length > limit;
    final docs = hasMore ? snap.docs.sublist(0, limit) : snap.docs;
    
    final items = docs.map((doc) => Job.fromMap(doc.data()..['id'] = doc.id)).toList();
    final lastDoc = docs.isNotEmpty ? docs.last : null;
    
    return (items: items, lastDoc: lastDoc, hasMore: hasMore);
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<void> updateJobStatus(String id, String status) async {
    try {
      final job = await getJob(id);
      if (job == null) return;
      if (job.status == status) return;

      DateTime jobDateTime = DateTime.now();
      try {
        jobDateTime = DateFormat('dd MMM yyyy').parse(job.date);
      } catch (_) {}
      final dateStr = DateFormat('yyyy-MM-dd').format(jobDateTime);
      final statsRef = _firestore.collection('garages').doc(garageId).collection('stats').doc(dateStr);

      await _firestore.runTransaction((transaction) async {
        // ─── ALL READS FIRST ───────────────────────────────────────────────
        final statsSnap = await transaction.get(statsRef);

        // ─── ALL WRITES AFTER ──────────────────────────────────────────────
        transaction.update(_collection.doc(id), {'status': status});

        if (statsSnap.exists) {
          final Map<String, dynamic> updates = {};

          if (job.status == 'pending') updates['pendingJobCount'] = FieldValue.increment(-1);
          if (job.status == 'in-progress') updates['inProgressJobCount'] = FieldValue.increment(-1);
          if (job.status == 'completed') updates['completedJobCount'] = FieldValue.increment(-1);

          if (status == 'pending') updates['pendingJobCount'] = FieldValue.increment(1);
          if (status == 'in-progress') updates['inProgressJobCount'] = FieldValue.increment(1);
          if (status == 'completed') updates['completedJobCount'] = FieldValue.increment(1);

          transaction.update(statsRef, updates);
        }
      });
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  Future<void> updateJob(Job job) async {
    assert(job.id != null, 'Cannot update a job without an id');
    try {
      final oldJob = await getJob(job.id!);
      
      // Update job document
      await _collection.doc(job.id).set(job.toMap());

      // If status changed, update stats
      if (oldJob != null && oldJob.status != job.status) {
        DateTime jobDateTime = DateTime.now();
        try {
          jobDateTime = DateFormat('dd MMM yyyy').parse(job.date);
        } catch (_) {}
        final dateStr = DateFormat('yyyy-MM-dd').format(jobDateTime);
        final statsRef = _firestore.collection('garages').doc(garageId).collection('stats').doc(dateStr);

        await _firestore.runTransaction((transaction) async {
          final statsSnap = await transaction.get(statsRef);
          if (statsSnap.exists) {
            final Map<String, dynamic> updates = {};
            
            if (oldJob.status == 'pending') updates['pendingJobCount'] = FieldValue.increment(-1);
            if (oldJob.status == 'in-progress') updates['inProgressJobCount'] = FieldValue.increment(-1);
            if (oldJob.status == 'completed') updates['completedJobCount'] = FieldValue.increment(-1);
            
            if (job.status == 'pending') updates['pendingJobCount'] = FieldValue.increment(1);
            if (job.status == 'in-progress') updates['inProgressJobCount'] = FieldValue.increment(1);
            if (job.status == 'completed') updates['completedJobCount'] = FieldValue.increment(1);
            
            transaction.update(statsRef, updates);
          }
        });
      }
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteJob(String id) async {
    try {
      // Decrement job count in stats on delete
      final job = await getJob(id);
      if (job != null) {
        DateTime jobDateTime = DateTime.now();
        try {
          jobDateTime = DateFormat('dd MMM yyyy').parse(job.date);
        } catch (_) {}
        final dateStr = DateFormat('yyyy-MM-dd').format(jobDateTime);
        final statsRef = _firestore.collection('garages').doc(garageId).collection('stats').doc(dateStr);

        await _firestore.runTransaction((transaction) async {
          // ─── ALL READS FIRST ─────────────────────────────────────────────
          final statsSnap = await transaction.get(statsRef);

          // ─── ALL WRITES AFTER ────────────────────────────────────────────
          transaction.delete(_collection.doc(id));

          if (statsSnap.exists) {
            final Map<String, dynamic> updates = {
              'jobCount': FieldValue.increment(-1),
            };
            if (job.status == 'pending') updates['pendingJobCount'] = FieldValue.increment(-1);
            if (job.status == 'in-progress') updates['inProgressJobCount'] = FieldValue.increment(-1);
            if (job.status == 'completed') updates['completedJobCount'] = FieldValue.increment(-1);
            transaction.update(statsRef, updates);
          }
        });
      } else {
        await _collection.doc(id).delete();
      }
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Sequential Numbering Generator ────────────────────────────────────────

  Future<String> generateNextJobNumber() async {
    final year = DateTime.now().year;
    final counterRef = _firestore
        .collection('garages')
        .doc(garageId)
        .collection('counters')
        .doc('jobs');

    try {
      return await _firestore.runTransaction<String>((transaction) async {
        final snap = await transaction.get(counterRef);
        int nextSeq = 1;
        if (snap.exists) {
          final data = snap.data();
          final storedYear = data?['year'] as int?;
          final currentSeq = data?['last_number'] as int?;
          if (storedYear == year && currentSeq != null) {
            nextSeq = currentSeq + 1;
          }
        }
        transaction.set(counterRef, {
          'year': year,
          'last_number': nextSeq,
        });
        return 'JC-$year-${nextSeq.toString().padLeft(4, '0')}';
      });
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }
}
