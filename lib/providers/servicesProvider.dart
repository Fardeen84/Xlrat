import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ServiceItem.dart';
import '../repository/ServiceRepository.dart';
import 'profile_provider.dart';
import 'billing_providers.dart';
import '../local_database/billing_database.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final garageId = ref.watch(profileProvider).garageId;
  return ServiceRepository(
    garageId: garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to update services. Please check your internet connection.",
  );
});

class ServiceState {
  final List<ServiceItem> items;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final String? error;
  final bool isSyncing;
  final int syncedCount;

  ServiceState({
    required this.items,
    required this.isLoading,
    required this.isLoadMore,
    required this.hasMore,
    this.error,
    this.isSyncing = false,
    this.syncedCount = 0,
  });

  factory ServiceState.initial() => ServiceState(
    items: [],
    isLoading: true,
    isLoadMore: false,
    hasMore: false,
    isSyncing: false,
    syncedCount: 0,
  );

  ServiceState copyWith({
    List<ServiceItem>? items,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    String? error,
    bool? isSyncing,
    int? syncedCount,
  }) {
    return ServiceState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isSyncing: isSyncing ?? this.isSyncing,
      syncedCount: syncedCount ?? this.syncedCount,
    );
  }
}

class ServiceListNotifier extends StateNotifier<ServiceState> {
  final ServiceRepository _repo;
  Timer? _syncTimer;

  ServiceListNotifier(this._repo) : super(ServiceState.initial()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load local items from SQLite cache immediately
    await _loadFromLocal();

    // 2. Run delta sync in background (unawaited so override in tests works)
    Future.microtask(() async {
      await triggerSync();
      // 3. Sync periodically every 5 minutes
      _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => triggerSync());
    });
  }

  Future<void> _loadFromLocal() async {
    try {
      final items = await _repo.getLocalItems();
      state = state.copyWith(
        items: items,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> triggerSync() async {
    state = state.copyWith(isSyncing: true, syncedCount: 0);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await _repo.syncFromFirestore(
        prefs,
        onProgress: (count) {
          state = state.copyWith(syncedCount: count);
        },
      );
      await _loadFromLocal();
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  Future<void> resyncAll() async {
    state = state.copyWith(isSyncing: true, syncedCount: 0);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final garageId = _repo.garageId;

      // Clear shared preferences keys
      await prefs.remove('services_last_sync_$garageId');
      await prefs.remove('services_updatedAt_repaired_$garageId');
      await prefs.remove('services_sync_date_$garageId');
      await prefs.remove('services_sync_daily_count_$garageId');
      await prefs.remove('services_sync_last_doc_id_$garageId');
      await prefs.remove('services_sync_total_synced_$garageId');
      await prefs.remove('services_last_orphan_check_$garageId');

      // Clear local database rows for this garage
      final db = await BillingDatabase.instance.database;
      await db.delete('services', where: 'garage_id = ?', whereArgs: [garageId]);

      // Re-trigger sync
      await _repo.syncFromFirestore(
        prefs,
        onProgress: (count) {
          state = state.copyWith(syncedCount: count);
        },
      );
      await _loadFromLocal();
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  Future<void> loadFirstPage() async {
    await _loadFromLocal();
  }

  Future<void> loadMore() async {
    state = state.copyWith(hasMore: false);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final servicesListStateProvider = StateNotifierProvider<ServiceListNotifier, ServiceState>((ref) {
  final repo = ref.watch(serviceRepositoryProvider);
  return ServiceListNotifier(repo);
});

final servicesListProvider = Provider.autoDispose<AsyncValue<List<ServiceItem>>>((ref) {
  final state = ref.watch(servicesListStateProvider);
  if (state.isLoading) {
    return const AsyncValue.loading();
  }
  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }
  return AsyncValue.data(state.items);
});

final servicesSearchProvider = StateProvider<String>((ref) => '');

final servicesSearchResultProvider = FutureProvider.autoDispose<List<ServiceItem>>((ref) async {
  final query = ref.watch(servicesSearchProvider);
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.searchItems(query);
});

final filteredServicesProvider = Provider.autoDispose<AsyncValue<List<ServiceItem>>>((ref) {
  final query = ref.watch(servicesSearchProvider);
  if (query.trim().isEmpty) {
    return ref.watch(servicesListProvider);
  }
  return ref.watch(servicesSearchResultProvider);
});
