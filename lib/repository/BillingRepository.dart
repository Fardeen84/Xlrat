import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/billing_model/BillingCustomer.dart';
import '../models/billing_model/BillingVehicle.dart';
import '../models/billing_model/InvoiceItem.dart';
import '../models/billing_model/invoice.dart';

/// Direct Firestore repository for billing invoices.
class BillingRepository {
  BillingRepository({required this.garageId, this.onInvoiceCreated, this.onWriteError, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String garageId;
  final Function(Invoice)? onInvoiceCreated;
  final Function(String)? onWriteError;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('garages').doc(garageId).collection('invoices');


  // ─── Create ───────────────────────────────────────────────────────────────

  Future<Invoice> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    try {
      final docRef = _collection.doc();
      final counterRef = _firestore
          .collection('garages')
          .doc(garageId)
          .collection('counters')
          .doc('invoices');

      final dateStr = DateFormat('yyyy-MM-dd').format(invoice.invoiceDate);
      final statsRef = _firestore
          .collection('garages')
          .doc(garageId)
          .collection('stats')
          .doc(dateStr);

      final toSave = await _firestore.runTransaction<Invoice>((transaction) async {
        // 1. Execute all reads first
        final counterSnap = await transaction.get(counterRef);
        final statsSnap = await transaction.get(statsRef);

        // 2. Generate next sequential invoice number
        int nextSeq = 1;
        if (counterSnap.exists) {
          final currentSeq = counterSnap.data()?['last_number'] as int?;
          if (currentSeq != null) {
            nextSeq = currentSeq + 1;
          }
        }

        final nextNumber = 'INV-${nextSeq.toString().padLeft(6, '0')}';

        // 3. Setup the invoice
        final populatedItems = items.map((item) => item.copyWith(invoiceId: docRef.id)).toList();
        final updatedInvoice = invoice.copyWith(
          id: docRef.id,
          invoiceNumber: nextNumber,
          items: populatedItems,
        );

        // 4. Perform writes
        transaction.set(counterRef, {
          'last_number': nextSeq,
        });
        transaction.set(docRef, updatedInvoice.toMap());

        // 5. Update Daily Stats rollup
        if (!statsSnap.exists) {
          final Map<String, dynamic> initialCustomerTotals = {
            updatedInvoice.customerId: {
              'revenue': updatedInvoice.grandTotal,
              'count': 1,
            }
          };
          final Map<String, dynamic> initialPartTotals = {};
          for (final item in updatedInvoice.items) {
            initialPartTotals[item.itemName] = {
              'revenue': item.total,
              'quantity': item.quantity,
            };
          }

          transaction.set(statsRef, {
            'totalRevenue': updatedInvoice.grandTotal,
            'invoiceCount': 1,
            'jobCount': 0,
            'pendingJobCount': 0,
            'inProgressJobCount': 0,
            'completedJobCount': 0,
            'customerTotals': initialCustomerTotals,
            'partTotals': initialPartTotals,
          });
        } else {
          final Map<String, dynamic> statsUpdates = {
            'totalRevenue': FieldValue.increment(updatedInvoice.grandTotal),
            'invoiceCount': FieldValue.increment(1),
          };
          statsUpdates['customerTotals.${updatedInvoice.customerId}.revenue'] =
              FieldValue.increment(updatedInvoice.grandTotal);
          statsUpdates['customerTotals.${updatedInvoice.customerId}.count'] =
              FieldValue.increment(1);

          for (final item in updatedInvoice.items) {
            statsUpdates['partTotals.${item.itemName}.revenue'] = FieldValue.increment(item.total);
            statsUpdates['partTotals.${item.itemName}.quantity'] = FieldValue.increment(item.quantity);
          }
          transaction.update(statsRef, statsUpdates);
        }

        return updatedInvoice;
      });

      onInvoiceCreated?.call(toSave);
      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<Invoice?> getInvoice(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return _hydrateInvoice(doc.data()!..['id'] = doc.id);
  }

  Stream<List<Invoice>> streamInvoices({int limit = 50}) {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snap) async {
      final list = await Future.wait(snap.docs.map((doc) => _hydrateInvoice(doc.data()..['id'] = doc.id)));
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<Invoice>> getInvoices({int? limit}) async {
    Query<Map<String, dynamic>> query = _collection.orderBy('created_at', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    final snap = await query.get();
    final list = await Future.wait(snap.docs.map((doc) => _hydrateInvoice(doc.data()..['id'] = doc.id)));
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<({List<Invoice> items, DocumentSnapshot? lastDoc, bool hasMore})> getInvoicesPaginated({
    required int limit,
    DocumentSnapshot? startAfter,
    String? query,
    PaymentStatus? status,
  }) async {
    Query<Map<String, dynamic>> queryBuilder = _collection.orderBy('created_at', descending: true);
    
    if (status != null) {
      queryBuilder = queryBuilder.where('payment_status', isEqualTo: status.name);
    }
    
    if (startAfter != null) {
      queryBuilder = queryBuilder.startAfterDocument(startAfter);
    }
    
    final snap = await queryBuilder.limit(limit + 1).get();
    final hasMore = snap.docs.length > limit;
    final docs = hasMore ? snap.docs.sublist(0, limit) : snap.docs;
    
    final items = await Future.wait(docs.map((doc) => _hydrateInvoice(doc.data()..['id'] = doc.id)));
    final lastDoc = docs.isNotEmpty ? docs.last : null;
    
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    var filtered = items;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = items.where((inv) =>
          inv.invoiceNumber.toLowerCase().contains(q) ||
          (inv.customer?.name.toLowerCase().contains(q) ?? false) ||
          (inv.customer?.mobile.contains(q) ?? false) ||
          (inv.vehicle?.vehicleNumber.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    
    return (items: filtered, lastDoc: lastDoc, hasMore: hasMore);
  }

  Future<List<Invoice>> getInvoicesByCustomer(String customerId) async {
    final snap = await _collection.where('customer_id', isEqualTo: customerId).get();
    final list = await Future.wait(snap.docs.map((doc) => _hydrateInvoice(doc.data()..['id'] = doc.id)));
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final list = await getInvoices();
    if (query.trim().isEmpty) return list;
    final q = query.trim().toLowerCase();
    return list.where((inv) =>
        inv.invoiceNumber.toLowerCase().contains(q) ||
        (inv.customer?.name.toLowerCase().contains(q) ?? false) ||
        (inv.customer?.mobile.contains(q) ?? false) ||
        (inv.vehicle?.vehicleNumber.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  Future<List<Invoice>> getInvoicesByStatus(PaymentStatus status) async {
    final snap = await _collection
        .where('payment_status', isEqualTo: status.name)
        .orderBy('created_at', descending: true)
        .get();
    final list = await Future.wait(snap.docs.map((doc) => _hydrateInvoice(doc.data()..['id'] = doc.id)));
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<({double total, int count})> getTodaySummary() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(today);
    final statsRef = _firestore.collection('garages').doc(garageId).collection('stats').doc(dateStr);
    
    final doc = await statsRef.get();
    if (!doc.exists) {
      return (total: 0.0, count: 0);
    }
    final data = doc.data()!;
    final total = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final count = data['invoiceCount'] as int? ?? 0;
    return (total: total, count: count);
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<Invoice> updateInvoice(Invoice invoice, List<InvoiceItem> items) async {
    assert(invoice.id != null, 'Cannot update an invoice without an id');
    try {
      final populatedItems = items.map((item) => item.copyWith(invoiceId: invoice.id)).toList();
      final toSave = invoice.copyWith(items: populatedItems);
      await _collection.doc(invoice.id).set(toSave.toMap());
      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteInvoice(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  Future<Invoice> _hydrateInvoice(Map<String, dynamic> data) async {
    final invoice = Invoice.fromMap(data);
    
    // Fetch Customer
    BillingCustomer? customer;
    final customerId = invoice.customerId;
    if (customerId.isNotEmpty) {
      final custDoc = await _firestore
          .collection('garages')
          .doc(garageId)
          .collection('customers')
          .doc(customerId)
          .get();
      if (custDoc.exists) {
        customer = BillingCustomer.fromMap(custDoc.data()!..['id'] = custDoc.id);
      }
    }

    // Fetch Vehicle
    BillingVehicle? vehicle;
    final vehicleId = invoice.vehicleId;
    if (vehicleId != null && vehicleId.isNotEmpty) {
      final vehDoc = await _firestore
          .collection('garages')
          .doc(garageId)
          .collection('vehicles')
          .doc(vehicleId)
          .get();
      if (vehDoc.exists) {
        vehicle = BillingVehicle.fromMap(vehDoc.data()!..['id'] = vehDoc.id);
      }
    }

    return invoice.copyWith(customer: customer, vehicle: vehicle);
  }

  // ─── Sequential Numbering Generator ────────────────────────────────────────

  Future<String> generateNextInvoiceNumber() async {
    final counterRef = _firestore
        .collection('garages')
        .doc(garageId)
        .collection('counters')
        .doc('invoices');

    try {
      return await _firestore.runTransaction<String>((transaction) async {
        final snap = await transaction.get(counterRef);
        int nextSeq = 1;
        if (snap.exists) {
          final currentSeq = snap.data()?['last_number'] as int?;
          if (currentSeq != null) {
            nextSeq = currentSeq + 1;
          }
        }
        transaction.set(counterRef, {
          'last_number': nextSeq,
        });
        return 'INV-${nextSeq.toString().padLeft(6, '0')}';
      });
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }
}
