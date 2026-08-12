import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/billing_model/invoice.dart';
import '../models/job.dart';

/// Backfills daily stats documents under garages/{garageId}/stats/{yyyy-MM-dd}
/// by reading all existing invoices and jobs once. This should only be run once.
Future<void> runOneTimeStatsBackfill(String garageId) async {
  final firestore = FirebaseFirestore.instance;

  // 1. Fetch all invoices
  final invoicesSnap = await firestore
      .collection('garages')
      .doc(garageId)
      .collection('invoices')
      .get();

  // 2. Fetch all jobs
  final jobsSnap = await firestore
      .collection('garages')
      .doc(garageId)
      .collection('jobs')
      .get();

  final Map<String, Map<String, dynamic>> dailyStats = {};

  // Process Invoices
  for (final doc in invoicesSnap.docs) {
    final invoice = Invoice.fromMap(doc.data()..['id'] = doc.id);
    final dateStr = DateFormat('yyyy-MM-dd').format(invoice.invoiceDate);

    if (!dailyStats.containsKey(dateStr)) {
      dailyStats[dateStr] = {
        'totalRevenue': 0.0,
        'invoiceCount': 0,
        'jobCount': 0,
        'pendingJobCount': 0,
        'inProgressJobCount': 0,
        'completedJobCount': 0,
        'customerTotals': {},
        'partTotals': {},
      };
    }

    final day = dailyStats[dateStr]!;
    day['totalRevenue'] = (day['totalRevenue'] as double) + invoice.grandTotal;
    day['invoiceCount'] = (day['invoiceCount'] as int) + 1;

    // Customer totals
    final customerTotals = day['customerTotals'] as Map<dynamic, dynamic>;
    if (!customerTotals.containsKey(invoice.customerId)) {
      customerTotals[invoice.customerId] = {'revenue': 0.0, 'count': 0};
    }
    customerTotals[invoice.customerId]['revenue'] =
        (customerTotals[invoice.customerId]['revenue'] as double) + invoice.grandTotal;
    customerTotals[invoice.customerId]['count'] =
        (customerTotals[invoice.customerId]['count'] as int) + 1;

    // Part totals
    final partTotals = day['partTotals'] as Map<dynamic, dynamic>;
    for (final item in invoice.items) {
      if (!partTotals.containsKey(item.itemName)) {
        partTotals[item.itemName] = {'revenue': 0.0, 'quantity': 0.0};
      }
      partTotals[item.itemName]['revenue'] =
          (partTotals[item.itemName]['revenue'] as double) + item.total;
      partTotals[item.itemName]['quantity'] =
          (partTotals[item.itemName]['quantity'] as num).toDouble() + item.quantity;
    }
  }

  // Process Jobs
  for (final doc in jobsSnap.docs) {
    final job = Job.fromMap(doc.data()..['id'] = doc.id);
    DateTime jobDateTime = DateTime.now();
    try {
      jobDateTime = DateFormat('dd MMM yyyy').parse(job.date);
    } catch (_) {}
    final dateStr = DateFormat('yyyy-MM-dd').format(jobDateTime);

    if (!dailyStats.containsKey(dateStr)) {
      dailyStats[dateStr] = {
        'totalRevenue': 0.0,
        'invoiceCount': 0,
        'jobCount': 0,
        'pendingJobCount': 0,
        'inProgressJobCount': 0,
        'completedJobCount': 0,
        'customerTotals': {},
        'partTotals': {},
      };
    }

    final day = dailyStats[dateStr]!;
    day['jobCount'] = (day['jobCount'] as int) + 1;
    if (job.status == 'pending') {
      day['pendingJobCount'] = (day['pendingJobCount'] as int) + 1;
    }
    if (job.status == 'in-progress') {
      day['inProgressJobCount'] = (day['inProgressJobCount'] as int) + 1;
    }
    if (job.status == 'completed') {
      day['completedJobCount'] = (day['completedJobCount'] as int) + 1;
    }
  }

  // Write dailyStats to Firestore in batches
  final statsCollection = firestore.collection('garages').doc(garageId).collection('stats');
  WriteBatch batch = firestore.batch();
  int counter = 0;

  for (final entry in dailyStats.entries) {
    final docRef = statsCollection.doc(entry.key);
    batch.set(docRef, entry.value, SetOptions(merge: true));
    counter++;
    if (counter >= 400) {
      await batch.commit();
      batch = firestore.batch();
      counter = 0;
    }
  }

  if (counter > 0) {
    await batch.commit();
  }
}

/// Backfills name_lower field in garages/{garageId}/inventory, secondhand_inventory, and services collections.
Future<void> runOneTimeNameLowerBackfill(String garageId) async {
  final firestore = FirebaseFirestore.instance;

  Future<void> backfillCollection(CollectionReference<Map<String, dynamic>> collection) async {
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
    bool hasMore = true;
    while (hasMore) {
      var query = collection.limit(500);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      final snap = await query.get();
      if (snap.docs.isEmpty) {
        hasMore = false;
        break;
      }
      WriteBatch batch = firestore.batch();
      int counter = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        if (!data.containsKey('name_lower')) {
          final name = data['name'] as String? ?? '';
          batch.update(doc.reference, {
            'name_lower': name.toLowerCase(),
            // Without bumping updatedAt, this write is invisible to the
            // delta sync (`where('updatedAt', isGreaterThan: lastSync)`),
            // so any device that had already synced this doc before
            // name_lower existed would keep a stale NULL name_lower in its
            // local SQLite forever, breaking local search for that item.
            'updatedAt': FieldValue.serverTimestamp(),
          });
          counter++;
        }
      }
      if (counter > 0) {
        await batch.commit();
      }
      lastDoc = snap.docs.last;
      if (snap.docs.length < 500) {
        hasMore = false;
      }
    }
  }

  // 1. Backfill inventory
  final inventoryCol = firestore
      .collection('garages')
      .doc(garageId)
      .collection('inventory');
  await backfillCollection(inventoryCol);

  // 2. Backfill secondhand_inventory
  final secondhandCol = firestore
      .collection('garages')
      .doc(garageId)
      .collection('secondhand_inventory');
  await backfillCollection(secondhandCol);

  // 3. Backfill services
  final servicesCol = firestore
      .collection('garages')
      .doc(garageId)
      .collection('services');
  await backfillCollection(servicesCol);
}
