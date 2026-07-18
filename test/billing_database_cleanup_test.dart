import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xlrat/local_database/billing_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('BillingDatabase Stale Sync Cleanup Tests', () {
    test('Clears stale sync keys on first app launch and sets done flag', () async {
      SharedPreferences.setMockInitialValues({
        'inventory_last_sync_garage123': 12345678,
        'secondhand_last_sync_garage123': 87654321,
        'other_key': 'keep_me',
      });

      // Triggers _runOneTimeStaleSyncCleanup via database getter
      await BillingDatabase.instance.database;

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('stale_inventory_sync_cleanup_v1_done'), isTrue);
      expect(prefs.containsKey('inventory_last_sync_garage123'), isFalse);
      expect(prefs.containsKey('secondhand_last_sync_garage123'), isFalse);
      expect(prefs.getString('other_key'), equals('keep_me'));
    });

    test('Does not run cleanup on subsequent launches if flag is set', () async {
      SharedPreferences.setMockInitialValues({
        'stale_inventory_sync_cleanup_v1_done': true,
        'inventory_last_sync_garage123': 12345678,
      });

      await BillingDatabase.instance.database;

      final prefs = await SharedPreferences.getInstance();
      // Should NOT clear since the flag was already true
      expect(prefs.containsKey('inventory_last_sync_garage123'), isTrue);
    });
  });
}
