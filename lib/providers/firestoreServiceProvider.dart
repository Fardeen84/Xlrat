import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((event) async {
      bool hasConnection = false;
      if (event is List<ConnectivityResult>) {
        hasConnection = event.any(
          (result) => result != ConnectivityResult.none,
        );
      } else if (event is ConnectivityResult) {
        hasConnection = event != ConnectivityResult.none;
      }

      if (!hasConnection) return false;
      return await isOnline();
    }).asBroadcastStream();
  }

  Future<bool> isOnline() async {
    // Check Firestore's own domain first — that's what actually matters
    // for sync. Fall back to a couple of other endpoints so a single
    // blocked/flaky domain doesn't cause a false "Offline" reading.
    if (await _pingUrl('https://firestore.googleapis.com')) return true;
    if (await _pingUrl('https://www.google.com')) return true;
    if (await _pingUrl('https://clients3.google.com/generate_204')) return true;
    return false;
  }

  Future<bool> _pingUrl(String url) async {
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      // Any HTTP response (even 404/405) proves DNS + network path work —
      // a genuinely offline device would time out or throw, not respond.
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
