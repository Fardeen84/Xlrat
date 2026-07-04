import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/AppNotification.dart';
import '../../providers/notificationsProvider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = notifications.where((n) => !n.read).toList();
    final read = notifications.where((n) => n.read).toList();

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            color: kCard,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 4,
              right: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
                  onPressed: () => context.go('/dashboard'),
                ),
                const Expanded(
                  child: Text('Notifications',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kForeground)),
                ),
                GestureDetector(
                  onTap: () => ref.read(notificationsProvider.notifier).markAllRead(),
                  child: const Text('Mark all read',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary)),
                ),
              ],
            ),
          ),

          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: kMutedForeground, fontSize: 14),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (unread.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('NEW (${unread.length})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                  color: kMutedForeground, letterSpacing: 0.8)),
                        ),
                        ...unread.map((n) => _NotifCard(notif: n, isNew: true)),
                      ],
                      if (read.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: Text('EARLIER',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                  color: kMutedForeground, letterSpacing: 0.8)),
                        ),
                        ...read.map((n) => _NotifCard(notif: n, isNew: false)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends ConsumerWidget {
  final AppNotification notif;
  final bool isNew;
  const _NotifCard({required this.notif, required this.isNew});

  static const _iconMap = {
    'service': (Icons.build_rounded, Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
    'stock':   (Icons.warning_amber_rounded, Color(0xFFFFF7ED), Color(0xFFC2410C)),
    'payment': (Icons.currency_rupee_rounded, Color(0xFFF0FDF4), Color(0xFF15803D)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = _iconMap[notif.type] ?? (Icons.notifications_rounded, kMuted, kMutedForeground);

    return InkWell(
      onTap: () {
        ref.read(notificationsProvider.notifier).markAsRead(notif.id);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isNew ? const Color(0xFFEFF6FF) : kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isNew ? const Color(0xFFBFDBFE) : kBorder.withOpacity(0.5),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: entry.$2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.$1, size: 18, color: entry.$3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
                        color: kForeground,
                      )),
                  const SizedBox(height: 3),
                  Text(notif.body,
                      style: const TextStyle(fontSize: 12, color: kMutedForeground, height: 1.4)),
                  const SizedBox(height: 6),
                  Text(notif.time,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kMutedForeground)),
                ],
              ),
            ),
            if (isNew)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}