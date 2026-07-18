

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/AppNotification.dart';
import '../models/billing_model/invoice.dart';
import 'billing_providers.dart';
import 'inventoryProvider.dart';
import 'profile_provider.dart';

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    final invoicesAsync = ref.watch(reportsInvoicesProvider);
    final lowStockAsync = ref.watch(lowStockItemsProvider);
    final invoices = invoicesAsync.value ?? [];
    final lowStock = lowStockAsync.value ?? [];

    final prefs = ref.watch(sharedPreferencesProvider);
    final readIdsList = prefs.getStringList('read_notification_ids') ?? [];
    final readIds = readIdsList.map((e) => int.tryParse(e)).whereType<int>().toSet();

    final List<AppNotification> list = [];

    // 1. Pending/overdue payments
    for (final invoice in invoices) {
      if (invoice.id != null && (invoice.paymentStatus == PaymentStatus.pending || invoice.paymentStatus == PaymentStatus.partial)) {
        final id = 100000 + invoice.id.hashCode.abs();
        final customerName = invoice.customer?.name ?? 'Customer';
        list.add(AppNotification(
          id: id,
          type: 'payment',
          title: 'Pending Payment',
          body: "$customerName has an outstanding amount of ₹${invoice.grandTotal.round()}",
          time: 'Due payment',
          read: readIds.contains(id),
        ));
      }
    }

    // 2. Low stock alerts
    for (final item in lowStock) {
      final id = 200000 + (item.id.hashCode.abs());
      list.add(AppNotification(
        id: id,
        type: 'stock',
        title: 'Low Stock Alert',
        body: '${item.name} has only ${item.stock} ${item.unit} left',
        time: 'Low Stock',
        read: readIds.contains(id),
      ));
    }

    // 3. Service reminders (invoices >= 90 days ago)
    final now = DateTime.now();
    for (final invoice in invoices) {
      if (invoice.id != null) {
        final days = now.difference(invoice.invoiceDate).inDays;
        if (days >= 90) {
          final id = 300000 + invoice.id.hashCode.abs();
          final customerName = invoice.customer?.name ?? 'Customer';
          final vehicleStr = invoice.vehicle != null ? ' (${invoice.vehicle!.vehicleNumber})' : '';
          list.add(AppNotification(
            id: id,
            type: 'service',
            title: 'Service Reminder',
            body: "Service is due for $customerName's vehicle$vehicleStr.",
            time: '$days days ago',
            read: readIds.contains(id),
          ));
        }
      }
    }

    return list;
  }

  void markAsRead(int id) {
    final prefs = ref.read(sharedPreferencesProvider);
    final readIdsList = prefs.getStringList('read_notification_ids') ?? [];
    final readIds = readIdsList.map((e) => int.tryParse(e)).whereType<int>().toSet();
    if (!readIds.contains(id)) {
      readIds.add(id);
      prefs.setStringList('read_notification_ids', readIds.map((e) => e.toString()).toList());
      ref.invalidateSelf();
    }
  }

  void markAllRead() {
    final prefs = ref.read(sharedPreferencesProvider);
    final allIds = state.map((n) => n.id).toList();
    prefs.setStringList('read_notification_ids', allIds.map((e) => e.toString()).toList());
    ref.invalidateSelf();
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.read).length;
});

