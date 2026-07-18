import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/billing_model/BillingCustomer.dart';

/// Direct Firestore repository for billing customers.
class CustomerRepository {
  CustomerRepository({required this.garageId, this.onWriteError, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String garageId;
  final Function(String)? onWriteError;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('garages').doc(garageId).collection('customers');

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<BillingCustomer> createCustomer(BillingCustomer customer) async {
    try {
      final docRef = _collection.doc();
      final toSave = customer.copyWith(id: docRef.id);
      await docRef.set(toSave.toMap());
      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<BillingCustomer?> getCustomer(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return BillingCustomer.fromMap(doc.data()!..['id'] = doc.id);
  }

  Stream<List<BillingCustomer>> streamCustomers({int limit = 50}) {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BillingCustomer.fromMap(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<List<BillingCustomer>> getCustomers() async {
    final snap = await _collection.orderBy('created_at', descending: true).get();
    return snap.docs
        .map((doc) => BillingCustomer.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<List<BillingCustomer>> searchCustomers(String query) async {
    final customers = await getCustomers();
    if (query.trim().isEmpty) return customers;
    final q = query.trim().toLowerCase();
    return customers.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.mobile.contains(q) ||
        c.email.toLowerCase().contains(q)).toList();
  }

  Future<({List<BillingCustomer> items, DocumentSnapshot? lastDoc, bool hasMore})> getCustomersPaginated({
    required int limit,
    DocumentSnapshot? startAfter,
    String? query,
  }) async {
    Query<Map<String, dynamic>> baseQuery = _collection.orderBy('created_at', descending: true);
    if (startAfter != null) {
      baseQuery = baseQuery.startAfterDocument(startAfter);
    }
    
    final snap = await baseQuery.limit(limit + 1).get();
    final hasMore = snap.docs.length > limit;
    final docs = hasMore ? snap.docs.sublist(0, limit) : snap.docs;
    
    final items = docs.map((doc) => BillingCustomer.fromMap(doc.data()..['id'] = doc.id)).toList();
    final lastDoc = docs.isNotEmpty ? docs.last : null;
    
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    var filtered = items;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = items.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.mobile.contains(q) ||
          c.email.toLowerCase().contains(q)
      ).toList();
    }
    
    return (items: filtered, lastDoc: lastDoc, hasMore: hasMore);
  }

  Future<int> getCustomerCount() async {
    final snap = await _collection.count().get();
    return snap.count ?? 0;
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<BillingCustomer> updateCustomer(BillingCustomer customer) async {
    assert(customer.id != null, 'Cannot update a customer without an id');
    try {
      await _collection.doc(customer.id).set(customer.toMap());
      return customer;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteCustomer(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }
}
