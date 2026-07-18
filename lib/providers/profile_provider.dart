import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider is not overridden');
});

final envConfigProvider = Provider<Map<String, String>>((ref) {
  throw UnimplementedError('envConfigProvider is not overridden');
});

class ProfileState {
  final String garageName;
  final String gstNumber;
  final String address;
  final String garageId;

  const ProfileState({
    required this.garageName,
    required this.gstNumber,
    required this.address,
    required this.garageId,
  });

  ProfileState copyWith({
    String? garageName,
    String? gstNumber,
    String? address,
    String? garageId,
  }) {
    return ProfileState(
      garageName: garageName ?? this.garageName,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      garageId: garageId ?? this.garageId,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final SharedPreferences _prefs;
  static const _keyGarageName = 'garage_name';
  static const _keyGstNumber = 'gst_number';
  static const _keyAddress = 'address';
  static const _keyGarageId = 'garage_id';

  ProfileNotifier(this._prefs)
      : super(_initializeState(_prefs));

  static ProfileState _initializeState(SharedPreferences prefs) {
    final garageName = prefs.getString(_keyGarageName) ?? '';
    final gstNumber = prefs.getString(_keyGstNumber) ?? '';
    final address = prefs.getString(_keyAddress) ?? '';
    final garageId = prefs.getString(_keyGarageId) ?? '';

    return ProfileState(
      garageName: garageName,
      gstNumber: gstNumber,
      address: address,
      garageId: garageId,
    );
  }

  Future<void> _updateFirestoreGarageField(String field, String value) async {
    if (state.garageId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('garages').doc(state.garageId).set({
          field: value,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error updating Firestore garage field: $e');
      }
    }
  }

  void setGarageId(String id) {
    _prefs.setString(_keyGarageId, id);
    state = state.copyWith(garageId: id);
  }

  void updateProfile({
    required String garageId,
    required String garageName,
    required String gstNumber,
    required String address,
  }) {
    _prefs.setString(_keyGarageId, garageId);
    _prefs.setString(_keyGarageName, garageName);
    _prefs.setString(_keyGstNumber, gstNumber);
    _prefs.setString(_keyAddress, address);
    state = ProfileState(
      garageId: garageId,
      garageName: garageName,
      gstNumber: gstNumber,
      address: address,
    );
  }

  void clearProfile() {
    _prefs.remove(_keyGarageId);
    _prefs.remove(_keyGarageName);
    _prefs.remove(_keyGstNumber);
    _prefs.remove(_keyAddress);
    state = const ProfileState(
      garageId: '',
      garageName: '',
      gstNumber: '',
      address: '',
    );
  }

  void updateGarageName(String name) {
    _prefs.setString(_keyGarageName, name);
    state = state.copyWith(garageName: name);
    _updateFirestoreGarageField('name', name);
  }

  void updateGstNumber(String gst) {
    _prefs.setString(_keyGstNumber, gst);
    state = state.copyWith(gstNumber: gst);
    _updateFirestoreGarageField('gstNumber', gst);
  }

  void updateAddress(String address) {
    _prefs.setString(_keyAddress, address);
    state = state.copyWith(address: address);
    _updateFirestoreGarageField('address', address);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileNotifier(prefs);
});

final profileLoadingProvider = StateProvider<bool>((ref) => false);



