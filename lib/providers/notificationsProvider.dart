

// ─── Notifications Provider ───────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/AppNotification.dart';
import '../models/CustomerModelas.dart';

final notificationsProvider = StateProvider<List<AppNotification>>((ref) => mockNotifications);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});
