import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((event) async {
      bool hasConnection = false;
      if (event is List<ConnectivityResult>) {
        hasConnection = event.any((result) => result != ConnectivityResult.none);
      } else if (event is ConnectivityResult) {
        hasConnection = event != ConnectivityResult.none;
      }
      
      if (!hasConnection) return false;
      return await isOnline();
    }).asBroadcastStream();
  }

  Future<bool> isOnline() async {
    try {
      final response = await http.head(
        Uri.parse('https://clients3.google.com/generate_204'),
      ).timeout(const Duration(seconds: 3));
      return response.statusCode == 204 || (response.statusCode >= 200 && response.statusCode < 300);
    } catch (_) {
      return false;
    }
  }
}
