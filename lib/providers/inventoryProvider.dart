import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/InventoryItem.dart';
import '../repository/InventoryRepository.dart';
import 'billing_providers.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(billingDatabaseProvider));
});

final inventoryListProvider = FutureProvider.autoDispose<List<InventoryItem>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.getAllItems();
});

final inventorySearchProvider = StateProvider<String>((ref) => '');

final filteredInventoryProvider = Provider.autoDispose<AsyncValue<List<InventoryItem>>>((ref) {
  final itemsAsync = ref.watch(inventoryListProvider);
  final query = ref.watch(inventorySearchProvider).toLowerCase();
  return itemsAsync.whenData((items) {
    if (query.isEmpty) return items;
    return items.where((i) =>
      i.name.toLowerCase().contains(query) ||
      i.category.toLowerCase().contains(query) ||
      i.sku.toLowerCase().contains(query)
    ).toList();
  });
});

final lowStockItemsProvider = Provider.autoDispose<AsyncValue<List<InventoryItem>>>((ref) {
  final itemsAsync = ref.watch(inventoryListProvider);
  return itemsAsync.whenData((items) {
    return items.where((i) => i.isLowStock).toList();
  });
});