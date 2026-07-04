import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider is not overridden');
});

class ProfileNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const _key = 'garage_name';

  ProfileNotifier(this._prefs) : super(_prefs.getString(_key) ?? '');

  void updateGarageName(String name) {
    _prefs.setString(_key, name);
    state = name;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileNotifier(prefs);
});
