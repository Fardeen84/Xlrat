// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final _notifications = [
    _Notif(1, 'service', 'Service Reminder',
        "Rajesh Kumar's Swift is due for service (45,000 km)", '10 min ago', false),
    _Notif(2, 'stock', 'Low Stock Alert',
        'Brake Pad Set – Front has only 2 units left', '1 hour ago', false),
    _Notif(3, 'payment', 'Pending Payment',
        'Priya Sharma has an outstanding amount of ₹3,200', '3 hours ago', false),
    _Notif(4, 'service', 'Service Reminder',
        "Mohammed Irfan's Innova is due for service next week", 'Yesterday', true),
    _Notif(5, 'stock', 'Low Stock Alert',
        'Oil Filter – Universal has only 3 units left', 'Yesterday', true),
    _Notif(6, 'payment', 'Payment Received',
        'Arun Nair paid ₹9,800 for job JC-2024-0149', '2 days ago', true),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.read).toList();
    final read = _notifications.where((n) => n.read).toList();

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
                  onTap: () {},
                  child: const Text('Mark all read',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary)),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
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

class _NotifCard extends StatelessWidget {
  final _Notif notif;
  final bool isNew;
  const _NotifCard({required this.notif, required this.isNew});

  static const _iconMap = {
    'service': (Icons.build_rounded, Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
    'stock':   (Icons.warning_amber_rounded, Color(0xFFFFF7ED), Color(0xFFC2410C)),
    'payment': (Icons.currency_rupee_rounded, Color(0xFFF0FDF4), Color(0xFF15803D)),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _iconMap[notif.type] ?? (Icons.notifications_rounded, kMuted, kMutedForeground);

    return Container(
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
    );
  }
}

class _Notif {
  final int id;
  final String type, title, body, time;
  final bool read;
  const _Notif(this.id, this.type, this.title, this.body, this.time, this.read);
}