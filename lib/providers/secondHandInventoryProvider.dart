import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/SecondHandItem.dart';
import '../repository/SecondHandInventoryRepository.dart';
import 'profile_provider.dart';
import 'billing_providers.dart';

import '../local_database/billing_database.dart';

final secondHandInventoryRepositoryProvider = Provider<SecondHandInventoryRepository>((ref) {
  final garageId = ref.watch(profileProvider).garageId;
  return SecondHandInventoryRepository(
    garageId: garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to update second-hand inventory. Please check your internet connection.",
  );
});

class SecondHandInventoryState {
  final List<SecondHandItem> items;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final String? error;
  final bool isSyncing;
  final int syncedCount;

  SecondHandInventoryState({
    required this.items,
    required this.isLoading,
    required this.isLoadMore,
    required this.hasMore,
    this.error,
    this.isSyncing = false,
    this.syncedCount = 0,
  });

  factory SecondHandInventoryState.initial() => SecondHandInventoryState(
    items: [],
    isLoading: true,
    isLoadMore: false,
    hasMore: false,
    isSyncing: false,
    syncedCount: 0,
  );

  SecondHandInventoryState copyWith({
    List<SecondHandItem>? items,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    String? error,
    bool? isSyncing,
    int? syncedCount,
  }) {
    return SecondHandInventoryState(
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

class SecondHandInventoryListNotifier extends StateNotifier<SecondHandInventoryState> {
  final SecondHandInventoryRepository _repo;
  Timer? _syncTimer;

  SecondHandInventoryListNotifier(this._repo) : super(SecondHandInventoryState.initial()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load local items from SQLite cache immediately
    await _loadFromLocal();

    // 2. Run delta sync in the background
    await triggerSync();

    // 3. Sync periodically every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => triggerSync());
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
      await prefs.remove('secondhand_last_sync_$garageId');
      await prefs.remove('secondhand_updatedAt_repaired_$garageId');
      await prefs.remove('secondhand_sync_date_$garageId');
      await prefs.remove('secondhand_sync_daily_count_$garageId');
      await prefs.remove('secondhand_sync_last_doc_id_$garageId');
      await prefs.remove('secondhand_sync_total_synced_$garageId');
      await prefs.remove('secondhand_last_orphan_check_$garageId');

      // Clear local database rows for this garage
      final db = await BillingDatabase.instance.database;
      await db.delete('secondhand_inventory', where: 'garage_id = ?', whereArgs: [garageId]);

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

final secondHandInventoryListStateProvider = StateNotifierProvider<SecondHandInventoryListNotifier, SecondHandInventoryState>((ref) {
  final repo = ref.watch(secondHandInventoryRepositoryProvider);
  return SecondHandInventoryListNotifier(repo);
});

final secondHandInventoryListProvider = Provider.autoDispose<AsyncValue<List<SecondHandItem>>>((ref) {
  final state = ref.watch(secondHandInventoryListStateProvider);
  if (state.isLoading) {
    return const AsyncValue.loading();
  }
  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }
  return AsyncValue.data(state.items);
});

final secondHandInventorySearchProvider = StateProvider<String>((ref) => '');

final secondHandSearchResultProvider = FutureProvider.autoDispose<List<SecondHandItem>>((ref) async {
  final query = ref.watch(secondHandInventorySearchProvider);
  final repo = ref.watch(secondHandInventoryRepositoryProvider);
  return repo.searchItems(query);
});

final filteredSecondHandInventoryProvider = Provider.autoDispose<AsyncValue<List<SecondHandItem>>>((ref) {
  final query = ref.watch(secondHandInventorySearchProvider);
  if (query.trim().isEmpty) {
    return ref.watch(secondHandInventoryListProvider);
  }
  return ref.watch(secondHandSearchResultProvider);
});
