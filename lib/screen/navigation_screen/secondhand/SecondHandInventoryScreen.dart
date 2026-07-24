import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/SecondHandItem.dart';
import '../../../providers/secondHandInventoryProvider.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';

class SecondHandInventoryScreen extends ConsumerStatefulWidget {
  const SecondHandInventoryScreen({super.key});

  @override
  ConsumerState<SecondHandInventoryScreen> createState() => _SecondHandInventoryScreenState();
}

class _SecondHandInventoryScreenState extends ConsumerState<SecondHandInventoryScreen> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.text = ref.read(secondHandInventorySearchProvider);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    if (value.trim().isEmpty) {
      ref.read(secondHandInventorySearchProvider.notifier).state = '';
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        ref.read(secondHandInventorySearchProvider.notifier).state = value;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(secondHandInventoryListStateProvider.notifier).loadMore();
    }
  }

  void _setSort(int index, bool ascending) {
    setState(() {
      _sortColumnIndex = index;
      _sortAscending = ascending;
    });
  }

  String _generateSku(String category) {
    final prefix = category.trim().isNotEmpty
        ? category
              .trim()
              .substring(
                0,
                category.trim().length >= 3 ? 3 : category.trim().length,
              )
              .toUpperCase()
        : 'SH';
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '$prefix-$suffix';
  }

  List<SecondHandItem> _getSortedItems(List<SecondHandItem> items) {
    List<SecondHandItem> displayList = List.from(items);

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
    final screenContext = context;
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'pcs');
    final purchaseCtrl = TextEditingController(text: '0');
    final sellingCtrl = TextEditingController(text: '0');
    final minStockCtrl = TextEditingController(text: '0');
    final sourceNotesCtrl = TextEditingController();
    final conditionNotesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          'Add Second Hand Part',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  style: TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter name'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  style: TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter category'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        decoration: InputDecoration(
                          labelText: 'Stock',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: kForeground),
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null)
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitCtrl,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
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
                        decoration: InputDecoration(
                          labelText: 'Purchase Price',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: kForeground),
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null)
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: sellingCtrl,
                        decoration: InputDecoration(
                          labelText: 'Selling Price',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: kForeground),
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null)
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: minStockCtrl,
                  decoration: InputDecoration(
                    labelText: 'Min Stock',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: kForeground),
                  validator: (value) =>
                      (value == null || int.tryParse(value) == null)
                      ? 'Invalid'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: skuCtrl,
                  decoration: InputDecoration(
                    labelText: 'SKU (Optional)',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  style: TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: sourceNotesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Source Notes (Optional)',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: conditionNotesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Condition Notes (Optional)',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: kForeground),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameCtrl.text.trim();
                final existing = await ref.read(secondHandInventoryRepositoryProvider).findByName(name);
                if (existing != null) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (warningContext) => AlertDialog(
                        backgroundColor: kCard,
                        title: Text(
                          'Duplicate Item',
                          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
                        ),
                        content: Text(
                          "An item named '$name' already exists. Do you want to update its stock instead, or use a different name?",
                          style: TextStyle(color: kForeground),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(warningContext),
                            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: kPrimaryDark,
                            ),
                            onPressed: () {
                              Navigator.pop(warningContext);
                              Navigator.pop(context);
                              _showAdjustStockDialog(screenContext, existing, true);
                            },
                            child: const Text('Update Stock'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                final category = categoryCtrl.text.trim();
                final sku = skuCtrl.text.trim().isNotEmpty
                    ? skuCtrl.text.trim()
                    : _generateSku(category);

                final newItem = SecondHandItem(
                  name: name,
                  category: category,
                  stock: int.parse(stockCtrl.text.trim()),
                  unit: unitCtrl.text.trim().isNotEmpty
                      ? unitCtrl.text.trim()
                      : 'pcs',
                  purchase: int.parse(purchaseCtrl.text.trim()),
                  selling: int.parse(sellingCtrl.text.trim()),
                  minStock: int.parse(minStockCtrl.text.trim()),
                  sku: sku,
                  sourceNotes: sourceNotesCtrl.text.trim(),
                  conditionNotes: conditionNotesCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );

                await ref.read(secondHandInventoryRepositoryProvider).createItem(newItem);
                ref.read(secondHandInventoryListStateProvider.notifier).loadFirstPage();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditPartDialog(BuildContext context, SecondHandItem item) {
    final screenContext = context;
    final nameCtrl = TextEditingController(text: item.name);
    final skuCtrl = TextEditingController(text: item.sku);
    final categoryCtrl = TextEditingController(text: item.category);
    final stockCtrl = TextEditingController(text: item.stock.toString());
    final unitCtrl = TextEditingController(text: item.unit);
    final purchaseCtrl = TextEditingController(text: item.purchase.toString());
    final sellingCtrl = TextEditingController(text: item.selling.toString());
    final minStockCtrl = TextEditingController(text: item.minStock.toString());
    final sourceNotesCtrl = TextEditingController(text: item.sourceNotes);
    final conditionNotesCtrl = TextEditingController(text: item.conditionNotes);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          'Edit Second Hand Part',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  style: TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter name'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  style: TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter category'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        decoration: InputDecoration(
                          labelText: 'Stock',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: kForeground),
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null)
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: unitCtrl,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
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
                        decoration: InputDecoration(
                          labelText: 'Purchase Price',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: kForeground),
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null)
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: sellingCtrl,
                        decoration: InputDecoration(
                          labelText: 'Selling Price',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: kForeground),
                        validator: (value) =>
                            (value == null || int.tryParse(value) == null)
                            ? 'Invalid'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: minStockCtrl,
                  decoration: InputDecoration(
                    labelText: 'Min Stock',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: kForeground),
                  validator: (value) =>
                      (value == null || int.tryParse(value) == null)
                      ? 'Invalid'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: skuCtrl,
                  decoration: InputDecoration(
                    labelText: 'SKU (Optional)',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  style: TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: sourceNotesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Source Notes (Optional)',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: conditionNotesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Condition Notes (Optional)',
                    labelStyle: TextStyle(color: kMutedForeground),
                  ),
                  maxLines: 2,
                  style: TextStyle(color: kForeground),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameCtrl.text.trim();
                final existing = await ref.read(secondHandInventoryRepositoryProvider).findByName(name);
                if (existing != null && existing.id != item.id) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (warningContext) => AlertDialog(
                        backgroundColor: kCard,
                        title: Text(
                          'Duplicate Item',
                          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
                        ),
                        content: Text(
                          "An item named '$name' already exists. Do you want to update its stock instead, or use a different name?",
                          style: TextStyle(color: kForeground),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(warningContext),
                            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: kPrimaryDark,
                            ),
                            onPressed: () {
                              Navigator.pop(warningContext);
                              Navigator.pop(context);
                              _showAdjustStockDialog(screenContext, existing, true);
                            },
                            child: const Text('Update Stock'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                final updatedItem = item.copyWith(
                  name: name,
                  category: categoryCtrl.text.trim(),
                  stock: int.parse(stockCtrl.text.trim()),
                  unit: unitCtrl.text.trim().isNotEmpty
                      ? unitCtrl.text.trim()
                      : 'pcs',
                  purchase: int.parse(purchaseCtrl.text.trim()),
                  selling: int.parse(sellingCtrl.text.trim()),
                  minStock: int.parse(minStockCtrl.text.trim()),
                  sku: skuCtrl.text.trim(),
                  sourceNotes: sourceNotesCtrl.text.trim(),
                  conditionNotes: conditionNotesCtrl.text.trim(),
                );
                await ref.read(secondHandInventoryRepositoryProvider).updateItem(updatedItem);
                ref.read(secondHandInventoryListStateProvider.notifier).loadFirstPage();
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

  void _showAdjustStockDialog(BuildContext context, SecondHandItem item, bool isAddition) {
    final qtyCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          isAddition ? 'Stock Add Karo' : 'Stock Kam Karo',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: qtyCtrl,
            decoration: InputDecoration(
              labelText: 'Quantity',
              labelStyle: TextStyle(color: kMutedForeground),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(color: kForeground),
            validator: (value) {
              if (value == null || int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Enter positive integer';
              }
              if (!isAddition && int.parse(value) > item.stock) {
                return 'Stock se zyada kam nahi kar sakte';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAddition ? kPrimary : kRed,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final adjustQty = int.parse(qtyCtrl.text.trim());
                final newStock = isAddition ? (item.stock + adjustQty) : (item.stock - adjustQty);
                if (item.id != null) {
                  await ref.read(secondHandInventoryRepositoryProvider).updateStock(item.id!, newStock);
                  ref.read(secondHandInventoryListStateProvider.notifier).loadFirstPage();
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: Text(isAddition ? 'Add' : 'Deduct', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, SecondHandItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          'Delete Second Hand Part?',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Text(
          'Are you sure you want to delete ${item.name}?',
          style: TextStyle(color: kForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () async {
              if (item.id == null) {
                Navigator.pop(dialogContext);
                return;
              }
              try {
                await ref.read(secondHandInventoryRepositoryProvider).deleteItem(item.id!);
                ref.read(secondHandInventoryListStateProvider.notifier).loadFirstPage();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Part deleted successfully')),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredSecondHandInventoryProvider);
    final inventoryState = ref.watch(secondHandInventoryListStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPC = constraints.maxWidth > 900;
        if (isPC) {
          return _buildPCLayout(context, itemsAsync, inventoryState);
        } else {
          return _buildMobileLayout(context, itemsAsync, inventoryState);
        }
      },
    );
  }

  Widget _buildPCLayout(
    BuildContext context,
    AsyncValue<List<SecondHandItem>> itemsAsync,
    SecondHandInventoryState inventoryState,
  ) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: kCard,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Second Hand Inventory',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kForeground,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.sync_rounded, color: kMutedForeground),
                          tooltip: 'Resync All',
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Starting full resync...')),
                            );
                            await ref.read(secondHandInventoryListStateProvider.notifier).resyncAll();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Full resync completed!')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddPartDialog(context),
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          label: const Text(
                            'Add Second Hand Part',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GarageSearchBar(
                        controller: _searchController,
                        hint: 'Search by Name, SKU, Category...',
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text('Error: $err', style: const TextStyle(color: kRed)),
                  ),
                  data: (items) {
                    final displayItems = _getSortedItems(items);
                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: kCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorder, width: 0.8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Theme(
                                data: Theme.of(context).copyWith(dividerColor: kBorder),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth - 48),
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      headingRowColor: WidgetStateProperty.all(kMuted.withOpacity(0.4)),
                                      headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: kForeground),
                                      columnSpacing: 32,
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      columns: [
                                        DataColumn(label: const Text('Name'), onSort: (index, asc) => _setSort(index, asc)),
                                        DataColumn(label: const Text('SKU'), onSort: (index, asc) => _setSort(index, asc)),
                                        DataColumn(label: const Text('Category'), onSort: (index, asc) => _setSort(index, asc)),
                                        DataColumn(label: const Text('Purchase'), numeric: true, onSort: (index, asc) => _setSort(index, asc)),
                                        DataColumn(label: const Text('Selling'), numeric: true, onSort: (index, asc) => _setSort(index, asc)),
                                        DataColumn(label: const Text('Stock'), onSort: (index, asc) => _setSort(index, asc)),
                                        const DataColumn(label: Text('Condition')),
                                        const DataColumn(label: Text('Actions')),
                                      ],
                                      rows: displayItems.map((item) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 180,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.history_rounded,
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
                                            DataCell(
                                              SizedBox(
                                                width: 150,
                                                child: Text(
                                                  item.conditionNotes.isNotEmpty ? item.conditionNotes : 'N/A',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, color: kMutedForeground),
                                                ),
                                              ),
                                            ),
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
                                                    icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: kMutedForeground),
                                                    onPressed: () => _showAdjustStockDialog(context, item, false),
                                                    tooltip: 'Deduct Stock',
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.edit_rounded, size: 18, color: kMutedForeground),
                                                    onPressed: () => _showEditPartDialog(context, item),
                                                    tooltip: 'Edit Part',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: kRed),
                                                    onPressed: () => _showDeleteConfirmDialog(context, item),
                                                    tooltip: 'Delete Part',
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
                          if (inventoryState.hasMore) ...[
                            const SizedBox(height: 24),
                            if (inventoryState.isLoadMore)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                                onPressed: () => ref.read(secondHandInventoryListStateProvider.notifier).loadMore(),
                                child: const Text('Load More', style: TextStyle(color: Colors.white)),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AsyncValue<List<SecondHandItem>> itemsAsync,
    SecondHandInventoryState inventoryState,
  ) {
    final items = itemsAsync.value ?? [];
    final footerCount = inventoryState.hasMore ? 1 : 0;
    final totalCount = items.length + footerCount;

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            color: kCard,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Second Hand Inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kForeground,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.sync_rounded, color: kMutedForeground, size: 20),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Starting full resync...')),
                            );
                            await ref.read(secondHandInventoryListStateProvider.notifier).resyncAll();
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Full resync completed!')),
                            );
                          },
                          tooltip: 'Resync All',
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showAddPartDialog(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GarageSearchBar(
                  controller: _searchController,
                  hint: 'Search secondhand stock...',
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: const TextStyle(color: kRed)),
              ),
              data: (items) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      if (inventoryState.isLoadMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                          onPressed: () => ref.read(secondHandInventoryListStateProvider.notifier).loadMore(),
                          child: const Text('Load More', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    }

                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isLowStock ? kRed.withOpacity(0.1) : kPrimary.withOpacity(0.1),
                              child: Icon(
                                Icons.history_rounded,
                                color: item.isLowStock ? kRed : kPrimary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(fontWeight: FontWeight.w700, color: kForeground, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Stock: ${item.stock} ${item.unit} • ₹${item.selling}',
                              style: TextStyle(
                                color: item.isLowStock ? kRed : kMutedForeground,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  children: [
                                    Divider(color: kBorder, height: 1),
                                    const SizedBox(height: 12),
                                    _buildDetailRow('SKU', item.sku),
                                    _buildDetailRow('Category', item.category),
                                    _buildDetailRow('Purchase Price', formatCurrency(item.purchase)),
                                    _buildDetailRow('Selling Price', formatCurrency(item.selling)),
                                    _buildDetailRow('Min Stock', '${item.minStock} ${item.unit}'),
                                    _buildDetailRow('Source Notes', item.sourceNotes.isNotEmpty ? item.sourceNotes : 'N/A'),
                                    _buildDetailRow('Condition Notes', item.conditionNotes.isNotEmpty ? item.conditionNotes : 'N/A'),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline_rounded, color: kPrimary),
                                          onPressed: () => _showAdjustStockDialog(context, item, true),
                                          tooltip: 'Add Stock',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.remove_circle_outline_rounded, color: kMutedForeground),
                                          onPressed: () => _showAdjustStockDialog(context, item, false),
                                          tooltip: 'Deduct Stock',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_rounded, color: kMutedForeground),
                                          onPressed: () => _showEditPartDialog(context, item),
                                          tooltip: 'Edit Part',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: kRed),
                                          onPressed: () => _showDeleteConfirmDialog(context, item),
                                          tooltip: 'Delete Part',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: kMutedForeground, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 12, color: kForeground, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
