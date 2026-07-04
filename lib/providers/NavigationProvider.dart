
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppScreen {
  splash, login, dashboard, customers, customerDetail,
  jobs, jobDetail, newJob, inventory, billing, invoice,
  reports, notifications, profile
}

final currentScreenProvider = StateProvider<AppScreen>((ref) => AppScreen.splash);

final screenHistoryProvider = StateProvider<List<AppScreen>>((ref) => [AppScreen.splash]);








