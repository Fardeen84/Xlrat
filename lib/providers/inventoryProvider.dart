import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/InventoryItem.dart';
import '../repository/InventoryRepository.dart';
import 'profile_provider.dart';
import 'billing_providers.dart';

import '../local_database/billing_database.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final garageId = ref.watch(profileProvider).garageId;
  return InventoryRepository(
    garageId: garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to update inventory. Please check your internet connection.",
  );
});

class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final String? error;
  final bool isSyncing;
  final int syncedCount;

  InventoryState({
    required this.items,
    required this.isLoading,
    required this.isLoadMore,
    required this.hasMore,
    this.error,
    this.isSyncing = false,
    this.syncedCount = 0,
  });

  factory InventoryState.initial() => InventoryState(
    items: [],
    isLoading: true,
    isLoadMore: false,
    hasMore: false,
    isSyncing: false,
    syncedCount: 0,
  );

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    String? error,
    bool? isSyncing,
    int? syncedCount,
  }) {
    return InventoryState(
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

class InventoryListNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository _repo;
  Timer? _syncTimer;

  InventoryListNotifier(this._repo) : super(InventoryState.initial()) {
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
      await prefs.remove('inventory_last_sync_$garageId');
      await prefs.remove('inventory_updatedAt_repaired_$garageId');
      await prefs.remove('inventory_sync_date_$garageId');
      await prefs.remove('inventory_sync_daily_count_$garageId');
      await prefs.remove('inventory_sync_last_doc_id_$garageId');
      await prefs.remove('inventory_sync_total_synced_$garageId');
      await prefs.remove('inventory_last_orphan_check_$garageId');
      await prefs.remove('inventory_orphan_check_last_doc_id_$garageId');

      // Clear local database rows for this garage
      final db = await BillingDatabase.instance.database;
      await db.delete('inventory', where: 'garage_id = ?', whereArgs: [garageId]);

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

final inventoryListStateProvider = StateNotifierProvider<InventoryListNotifier, InventoryState>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  return InventoryListNotifier(repo);
});

// Wrapped to maintain backward compatibility with components watching inventoryListProvider
final inventoryListProvider = Provider.autoDispose<AsyncValue<List<InventoryItem>>>((ref) {
  final state = ref.watch(inventoryListStateProvider);
  if (state.isLoading) {
    return const AsyncValue.loading();
  }
  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }
  return AsyncValue.data(state.items);
});

final inventorySearchProvider = StateProvider<String>((ref) => '');

final searchResultProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) async {
  final query = ref.watch(inventorySearchProvider);
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.searchItems(query);
});

final filteredInventoryProvider = Provider.autoDispose<AsyncValue<List<InventoryItem>>>((ref) {
  final query = ref.watch(inventorySearchProvider);
  if (query.trim().isEmpty) {
    return ref.watch(inventoryListProvider);
  }
  return ref.watch(searchResultProvider);
});

final lowStockItemsProvider = StreamProvider.autoDispose<List<InventoryItem>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final coll = FirebaseFirestore.instance
      .collection('garages')
      .doc(repo.garageId)
      .collection('inventory');
  return coll
      .where('isLowStock', isEqualTo: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => InventoryItem.fromMap(doc.data()..['id'] = doc.id))
          .toList());
});