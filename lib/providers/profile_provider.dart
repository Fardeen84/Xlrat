import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider is not overridden');
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

    String? garageId = prefs.getString(_keyGarageId);
    if (garageId == null || garageId.isEmpty) {
      garageId = const Uuid().v4();
      prefs.setString(_keyGarageId, garageId);
    }

    return ProfileState(
      garageName: garageName,
      gstNumber: gstNumber,
      address: address,
      garageId: garageId,
    );
  }

  void updateGarageName(String name) {
    _prefs.setString(_keyGarageName, name);
    state = state.copyWith(garageName: name);
  }

  void updateGstNumber(String gst) {
    _prefs.setString(_keyGstNumber, gst);
    state = state.copyWith(gstNumber: gst);
  }

  void updateAddress(String address) {
    _prefs.setString(_keyAddress, address);
    state = state.copyWith(address: address);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileNotifier(prefs);
});

