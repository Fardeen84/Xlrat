import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/billing_model/BillingVehicle.dart';

/// Direct Firestore repository for billing vehicles.
class VehicleRepository {
  VehicleRepository({required this.garageId, this.onWriteError, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String garageId;
  final Function(String)? onWriteError;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('garages').doc(garageId).collection('vehicles');

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<BillingVehicle> createVehicle(BillingVehicle vehicle) async {
    try {
      final docRef = _collection.doc();
      final toSave = vehicle.copyWith(id: docRef.id);
      await docRef.set(toSave.toMap());
      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Future<BillingVehicle?> getVehicle(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return BillingVehicle.fromMap(doc.data()!..['id'] = doc.id);
  }

  Stream<List<BillingVehicle>> streamVehicles({int limit = 50}) {
    return _collection.limit(limit).snapshots().map((snap) => snap.docs
        .map((doc) => BillingVehicle.fromMap(doc.data()..['id'] = doc.id))
        .toList());
  }

  Future<List<BillingVehicle>> getAllVehicles() async {
    final snap = await _collection.get();
    return snap.docs
        .map((doc) => BillingVehicle.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<List<BillingVehicle>> getVehiclesForCustomer(String customerId) async {
    final snap = await _collection.where('customer_id', isEqualTo: customerId).get();
    return snap.docs
        .map((doc) => BillingVehicle.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<List<BillingVehicle>> searchVehicles(String query) async {
    final vehicles = await getAllVehicles();
    if (query.trim().isEmpty) return vehicles;
    final q = query.trim().toUpperCase();
    return vehicles.where((v) => v.vehicleNumber.toUpperCase().contains(q)).toList();
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<BillingVehicle> updateVehicle(BillingVehicle vehicle) async {
    assert(vehicle.id != null, 'Cannot update a vehicle without an id');
    try {
      await _collection.doc(vehicle.id).set(vehicle.toMap());
      return vehicle;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteVehicle(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }
}
