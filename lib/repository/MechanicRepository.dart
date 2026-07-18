import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Mechanic.dart';

/// Direct Firestore repository for mechanics.
class MechanicRepository {
  MechanicRepository({required this.garageId, this.onWriteError, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String garageId;
  final Function(String)? onWriteError;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('garages').doc(garageId).collection('mechanics');

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<Mechanic> createMechanic(Mechanic mechanic) async {
    try {
      final docRef = _collection.doc();
      final toSave = mechanic.copyWith(id: docRef.id);
      await docRef.set(toSave.toMap());
      return toSave;
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<void> updateMechanic(Mechanic mechanic) async {
    assert(mechanic.id != null, 'Cannot update a mechanic without an id');
    try {
      await _collection.doc(mechanic.id).set(mechanic.toMap());
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteMechanic(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      onWriteError?.call(e.toString());
      rethrow;
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Stream<List<Mechanic>> streamMechanics({int limit = 50}) {
    return _collection.limit(limit).snapshots().map((snap) => snap.docs
        .map((doc) => Mechanic.fromMap(doc.data()..['id'] = doc.id))
        .toList());
  }

  Future<List<Mechanic>> getAllMechanics({bool activeOnly = true}) async {
    final snap = await _collection.get();
    var list = snap.docs
        .map((doc) => Mechanic.fromMap(doc.data()..['id'] = doc.id))
        .toList();
    if (activeOnly) {
      list = list.where((m) => m.isActive).toList();
    }
    return list;
  }
}
