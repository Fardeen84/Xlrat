
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/CustomerModelas.dart';
import '../models/InventoryItem.dart';

final inventoryProvider = StateProvider<List<InventoryItem>>((ref) => mockInventory);

final inventorySearchProvider = StateProvider<String>((ref) => '');

final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryProvider);
  final query = ref.watch(inventorySearchProvider).toLowerCase();
  if (query.isEmpty) return items;
  return items.where((i) =>
  i.name.toLowerCase().contains(query) ||
      i.category.toLowerCase().contains(query)
  ).toList();
});

final lowStockItemsProvider = Provider<List<InventoryItem>>((ref) {
  return ref.watch(inventoryProvider).where((i) => i.isLowStock).toList();
});