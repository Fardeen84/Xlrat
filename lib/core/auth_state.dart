import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  static bool isLoggedIn = false;

  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('hashed_pin');
  }

  static Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    await prefs.setString('hashed_pin', digest.toString());
    isLoggedIn = true;
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('hashed_pin');
    if (stored == null) return false;
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    final verified = stored == digest.toString();
    if (verified) {
      isLoggedIn = true;
    }
    return verified;
  }

  static void logout() {
    isLoggedIn = false;
  }
}
