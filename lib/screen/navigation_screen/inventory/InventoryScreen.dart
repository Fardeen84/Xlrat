import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../models/InventoryItem.dart';
import '../../../providers/inventoryProvider.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  int _selectedTab = 0; // 0: All, 1: Low Stock
  int? _sortColumnIndex;
  bool _sortAscending = true;

  void _setSort(int index, bool ascending) {
    setState(() {
      _sortColumnIndex = index;
      _sortAscending = ascending;
    });
  }

  List<InventoryItem> _getFilteredAndSortedItems(List<InventoryItem> items, List<InventoryItem> lowStock) {
    List<InventoryItem> displayList = _selectedTab == 0 ? items : items.where((i) => i.isLowStock).toList();

    if (_sortColumnIndex != null) {
      displayList.sort((a, b) {
        dynamic aValue;
        dynamic bValue;
        switch (_sortColumnIndex) {
          case 0:
            aValue = a.name;
            bValue = b.name;
            break;
          case 1:
            aValue = a.sku;
            bValue = b.sku;
            break;
          case 2:
            aValue = a.category;
            bValue = b.category;
            break;
          case 3:
            aValue = a.purchase;
            bValue = b.purchase;
            break;
          case 4:
            aValue = a.selling;
            bValue = b.selling;
            break;
          case 5:
            aValue = a.stock;
            bValue = b.stock;
            break;
          case 6:
            aValue = a.minStock;
            bValue = b.minStock;
            break;
          default:
            return 0;
        }
        if (_sortAscending) {
          return Comparable.compare(aValue, bValue);
        } else {
          return Comparable.compare(bValue, aValue);
        }
      });
    }
    return displayList;
  }

  void _showAddPartDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final unitCtrl = TextEditingController(text: 'pcs');
    final purchaseCtrl = TextEditingController(text: '0');
    final sellingCtrl = TextEditingController(text: '0');
    final minStockCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Add Part', style: TextStyle(fontWeight: FontWeight.w800, color: kForeground)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU (Optional)', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category *', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter category' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock', labelStyle: TextStyle(color: kMutedForeground)),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: kForeground),
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: kMutedForeground)),
                        style: const TextStyle(color: kForeground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: purchaseCtrl,
                        decoration: const InputDecoration(labelText: 'Purchase Price', labelStyle: TextStyle(color: kMutedForeground)),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: kForeground),
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: sellingCtrl,
                        decoration: const InputDecoration(labelText: 'Selling Price', labelStyle: TextStyle(color: kMutedForeground)),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: kForeground),
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: minStockCtrl,
                  decoration: const InputDecoration(labelText: 'Min Stock', labelStyle: TextStyle(color: kMutedForeground)),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newItem = InventoryItem(
                  name: nameCtrl.text.trim(),
                  category: categoryCtrl.text.trim(),
                  stock: int.parse(stockCtrl.text.trim()),
                  unit: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'pcs',
                  purchase: int.parse(purchaseCtrl.text.trim()),
                  selling: int.parse(sellingCtrl.text.trim()),
                  minStock: int.parse(minStockCtrl.text.trim()),
                  sku: skuCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                await ref.read(inventoryRepositoryProvider).createItem(newItem);
                ref.invalidate(inventoryListProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, InventoryItem item, bool isAddition) {
    final qtyCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          int getQty() => int.tryParse(qtyCtrl.text) ?? 0;
          void setQty(int val) {
            qtyCtrl.text = val.clamp(1, 999999).toString();
          }

          return AlertDialog(
            backgroundColor: kCard,
            title: Text(isAddition ? 'Add Stock' : 'Deduct Stock', style: const TextStyle(fontWeight: FontWeight.w800, color: kForeground)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 13, color: kMutedForeground)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final current = getQty();
                          if (current > 1) {
                            setStateDialog(() => setQty(current - 1));
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: kMuted,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.remove_rounded, color: kForeground),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: qtyCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: kForeground, fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) => (value == null || int.tryParse(value) == null || int.parse(value) <= 0) ? 'Invalid' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          final current = getQty();
                          setStateDialog(() => setQty(current + 1));
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: kMuted,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_rounded, color: kForeground),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [5, 10, 20].map((step) => OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        final current = getQty();
                        setStateDialog(() => setQty(current + step));
                      },
                      child: Text('+$step'),
                    )).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: kMutedForeground)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final qty = getQty();
                    final newStock = isAddition ? (item.stock + qty) : (item.stock - qty).clamp(0, 999999);
                    await ref.read(inventoryRepositoryProvider).updateStock(item.id!, newStock);
                    ref.invalidate(inventoryListProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditPartDialog(BuildContext context, InventoryItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final skuCtrl = TextEditingController(text: item.sku);
    final categoryCtrl = TextEditingController(text: item.category);
    final stockCtrl = TextEditingController(text: item.stock.toString());
    final unitCtrl = TextEditingController(text: item.unit);
    final purchaseCtrl = TextEditingController(text: item.purchase.toString());
    final sellingCtrl = TextEditingController(text: item.selling.toString());
    final minStockCtrl = TextEditingController(text: item.minStock.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Edit Part', style: TextStyle(fontWeight: FontWeight.w800, color: kForeground)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU (Optional)', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category *', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter category' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock', labelStyle: TextStyle(color: kMutedForeground)),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: kForeground),
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: kMutedForeground)),
                        style: const TextStyle(color: kForeground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: purchaseCtrl,
                        decoration: const InputDecoration(labelText: 'Purchase Price', labelStyle: TextStyle(color: kMutedForeground)),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: kForeground),
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: sellingCtrl,
                        decoration: const InputDecoration(labelText: 'Selling Price', labelStyle: TextStyle(color: kMutedForeground)),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: kForeground),
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: minStockCtrl,
                  decoration: const InputDecoration(labelText: 'Min Stock', labelStyle: TextStyle(color: kMutedForeground)),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updatedItem = item.copyWith(
                  name: nameCtrl.text.trim(),
                  category: categoryCtrl.text.trim(),
                  stock: int.parse(stockCtrl.text.trim()),
                  unit: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'pcs',
                  purchase: int.parse(purchaseCtrl.text.trim()),
                  selling: int.parse(sellingCtrl.text.trim()),
                  minStock: int.parse(minStockCtrl.text.trim()),
                  sku: skuCtrl.text.trim(),
                );
                await ref.read(inventoryRepositoryProvider).updateItem(updatedItem);
                ref.invalidate(inventoryListProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredInventoryProvider);
    final lowStockItemsAsync = ref.watch(lowStockItemsProvider);

    return itemsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err', style: const TextStyle(color: kRed)))),
      data: (items) {
        return lowStockItemsAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err', style: const TextStyle(color: kRed)))),
          data: (lowStockItems) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isPC = constraints.maxWidth > 900;
                if (isPC) {
                  return _buildPCLayout(context, items, lowStockItems);
                } else {
                  return _buildMobileLayout(context, items, lowStockItems);
                }
              },
            );
          },
        );
      },
    );
  }

  // ── PC Mode Layout (Data Table View) ───────────────────────────────────────
  Widget _buildPCLayout(BuildContext context, List<InventoryItem> items, List<InventoryItem> lowStockItems) {
    final displayItems = _getFilteredAndSortedItems(items, lowStockItems);

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Controls
          Container(
            color: kCard,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.inventoryTitle,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kForeground),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPartDialog(context),
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      label: Text(AppLocalizations.of(context)!.inventoryAddPart, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Tabs/Filters
                    Container(
                      decoration: BoxDecoration(
                        color: kMuted.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _tabButton(0, '${AppLocalizations.of(context)!.inventoryTabAll} (${items.length})'),
                          const SizedBox(width: 4),
                          _tabButton(1, '${AppLocalizations.of(context)!.inventoryTabLowStock} (${lowStockItems.length})', isWarning: lowStockItems.isNotEmpty),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Search Bar
                    Expanded(
                      child: GarageSearchBar(
                        hint: AppLocalizations.of(context)!.inventorySearchHint,
                        onChanged: (v) => ref.read(inventorySearchProvider.notifier).state = v,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Table Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder, width: 0.8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: kBorder,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(kMuted.withOpacity(0.4)),
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: kForeground),
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColName),
                            onSort: (index, asc) => _setSort(index, asc),
                          ),
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColSku),
                            onSort: (index, asc) => _setSort(index, asc),
                          ),
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColCategory),
                            onSort: (index, asc) => _setSort(index, asc),
                          ),
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColPurchase),
                            numeric: true,
                            onSort: (index, asc) => _setSort(index, asc),
                          ),
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColSelling),
                            numeric: true,
                            onSort: (index, asc) => _setSort(index, asc),
                          ),
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColStock),
                            onSort: (index, asc) => _setSort(index, asc),
                          ),
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColMinStock),
                            numeric: true,
                            onSort: (index, asc) => _setSort(index, asc),
                          ),
                          DataColumn(
                            label: Text(AppLocalizations.of(context)!.inventoryColActions),
                          ),
                        ],
                        rows: displayItems.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_rounded,
                                        size: 16,
                                        color: item.isLowStock ? kRed : kPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(item.sku)),
                              DataCell(Text(item.category)),
                              DataCell(Text(formatCurrency(item.purchase))),
                              DataCell(Text(formatCurrency(item.selling))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isLowStock ? kRed.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.stock} ${item.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.isLowStock ? kRed : kForeground,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text('${item.minStock} ${item.unit}')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: kPrimary),
                                      onPressed: () => _showAdjustStockDialog(context, item, true),
                                      tooltip: 'Add Stock',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: kMutedForeground),
                                      onPressed: () => _showAdjustStockDialog(context, item, false),
                                      tooltip: 'Deduct Stock',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, size: 18, color: kMutedForeground),
                                      onPressed: () => _showEditPartDialog(context, item),
                                      tooltip: 'Edit Part',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label, {bool isWarning = false}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kCard : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWarning && index == 1) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected
                    ? kForeground
                    : (isWarning ? kRed.withOpacity(0.8) : kMutedForeground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile Mode Layout (List Card View) ────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, List<InventoryItem> items, List<InventoryItem> lowStockItems) {
    final displayItems = _selectedTab == 0 ? items : lowStockItems;

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            color: kCard,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16, right: 16, bottom: 12,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.inventoryTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
                    Row(
                      children: [
                        PopupMenuButton<int>(
                          icon: const Icon(Icons.filter_list_rounded, color: kMutedForeground, size: 20),
                          color: kCard,
                          onSelected: (val) => setState(() => _selectedTab = val),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 0, child: Text('All Parts', style: TextStyle(color: kForeground))),
                            const PopupMenuItem(value: 1, child: Text('Low Stock Only', style: TextStyle(color: kForeground))),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showAddPartDialog(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GarageSearchBar(
                  hint: AppLocalizations.of(context)!.inventorySearchHint,
                  onChanged: (v) => ref.read(inventorySearchProvider.notifier).state = v,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                if (_selectedTab == 1 && lowStockItems.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('${lowStockItems.length} items below minimum stock',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                ...displayItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InventoryCard(
                    item: item,
                    onAdjustStock: _showAdjustStockDialog,
                    onEdit: _showEditPartDialog,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends ConsumerWidget {
  final InventoryItem item;
  final Function(BuildContext, InventoryItem, bool) onAdjustStock;
  final Function(BuildContext, InventoryItem) onEdit;

  const _InventoryCard({
    required this.item,
    required this.onAdjustStock,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GarageCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: kCard,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded, color: kPrimary),
                  title: const Text('Add Stock', style: TextStyle(color: kForeground)),
                  onTap: () {
                    Navigator.pop(context);
                    onAdjustStock(context, item, true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline_rounded, color: kMutedForeground),
                  title: const Text('Deduct Stock', style: TextStyle(color: kForeground)),
                  onTap: () {
                    Navigator.pop(context);
                    onAdjustStock(context, item, false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: kMutedForeground),
                  title: const Text('Edit Part', style: TextStyle(color: kForeground)),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit(context, item);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: item.isLowStock ? const Color(0xFFFFEBEE) : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_rounded, size: 22,
                color: item.isLowStock ? kRed : kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kForeground)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(6)),
                      child: Text(item.category, style: const TextStyle(fontSize: 10, color: kMutedForeground, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text('SKU: ${item.sku}', style: const TextStyle(fontSize: 10, color: kMutedForeground)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Sell: ${formatCurrency(item.selling)}', style: const TextStyle(fontSize: 11, color: kForeground, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('Cost: ${formatCurrency(item.purchase)}', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.stock} ${item.unit}',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: item.isLowStock ? kRed : kForeground,
                ),
              ),
              const SizedBox(height: 4),
              if (item.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Low Stock', style: TextStyle(fontSize: 10, color: kRed, fontWeight: FontWeight.w700)),
                )
              else
                Text('Min: ${item.minStock}', style: const TextStyle(fontSize: 10, color: kMutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}
