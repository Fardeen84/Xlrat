import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/billing_model/invoice.dart';
import '../repository/BillingRepository.dart';

class ReminderService {
  final BillingRepository _billingRepository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  ReminderService(this._billingRepository);

  tz.Location get _localLocation {
    try {
      return tz.local;
    } catch (_) {
      return tz.UTC;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    if (Platform.isWindows) {
      print('ReminderService: Local notifications are not supported on Windows. Skipping.');
      return;
    }

    try {
      // Initialize timezone database
      tz.initializeTimeZones();
      
      // Fallback location config
      try {
        final localZone = tz.local;
      } catch (e) {
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      const LinuxInitializationSettings initializationSettingsLinux =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
      );

      _initialized = true;

      // Reinitialize reminders from database on app start
      await reinitializeReminders();
    } catch (e) {
      print('ReminderService initialization failed: $e');
    }
  }

  Future<void> scheduleReminderForInvoice(Invoice invoice) async {
    if (Platform.isWindows) return;
    if (invoice.id == null) return;

    try {
      final scheduledDate = invoice.invoiceDate.add(const Duration(days: 90));
      if (scheduledDate.isBefore(DateTime.now())) {
        // Already passed 90 days, no need to schedule
        return;
      }

      final customerName = invoice.customer?.name ?? 'Customer';
      final vehicleInfo = invoice.vehicle != null
          ? ' (${invoice.vehicle!.vehicleNumber})'
          : '';

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'service_reminder_channel',
        'Service Reminders',
        channelDescription: 'Notifications for vehicle service reminders after 3 months',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // Convert scheduledDate to TZDateTime using safe timezone location
      final tzDateTime = tz.TZDateTime.from(scheduledDate, _localLocation);

      await _notificationsPlugin.zonedSchedule(
        invoice.id.hashCode.abs(),
        'Service Due Reminder',
        'Service is due for $customerName\'s vehicle$vehicleInfo.',
        tzDateTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stackTrace) {
      print('Failed to schedule reminder for invoice ${invoice.id}: $e');
      print(stackTrace);
    }
  }

  Future<void> reinitializeReminders() async {
    if (Platform.isWindows) return;
    try {
      // Cancel all existing scheduled notifications first to avoid duplicates
      await _notificationsPlugin.cancelAll();

      final invoices = await _billingRepository.getInvoices();
      final now = DateTime.now();

      for (final invoice in invoices) {
        final scheduledDate = invoice.invoiceDate.add(const Duration(days: 90));
        if (scheduledDate.isAfter(now)) {
          await scheduleReminderForInvoice(invoice);
        }
      }
    } catch (e, stackTrace) {
      print('Failed to reinitialize reminders: $e');
      print(stackTrace);
    }
  }
}
