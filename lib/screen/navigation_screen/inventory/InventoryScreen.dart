import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.text = ref.read(inventorySearchProvider);
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
      ref.read(inventorySearchProvider.notifier).state = '';
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        ref.read(inventorySearchProvider.notifier).state = value;
      });
    }
  }

  void _onScroll() {
    // Scroll triggers loading next page to conserve read limits
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(inventoryListStateProvider.notifier).loadMore();
    }
  }

  void _setSort(int index, bool ascending) {
    setState(() {
      _sortColumnIndex = index;
      _sortAscending = ascending;
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(inventoryListStateProvider.notifier).resyncAll();
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
        : 'PRT';
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
      7,
    );
    return '$prefix-$suffix';
  }

  List<InventoryItem> _getFilteredAndSortedItems(
      List<InventoryItem> items,
      List<InventoryItem> lowStock,
      ) {
    List<InventoryItem> displayList = _selectedTab == 0
        ? items
        : items.where((i) => i.isLowStock).toList();

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
    final screenContext = context;
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
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kCard,
              title: Text(
                'Add Part',
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isSaving = true;
                            });
                            try {
                              final name = nameCtrl.text.trim();
                              final existing = await ref.read(inventoryRepositoryProvider).findByName(name);
                              if (existing != null) {
                                if (context.mounted) {
                                  setState(() {
                                    isSaving = false;
                                  });
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

                              final newItem = InventoryItem(
                                name: name,
                                category: categoryCtrl.text.trim(),
                                stock: int.parse(stockCtrl.text.trim()),
                                unit: unitCtrl.text.trim().isNotEmpty
                                    ? unitCtrl.text.trim()
                                    : 'pcs',
                                purchase: int.parse(purchaseCtrl.text.trim()),
                                selling: int.parse(sellingCtrl.text.trim()),
                                minStock: int.parse(minStockCtrl.text.trim()),
                                sku: _generateSku(categoryCtrl.text.trim()),
                                createdAt: DateTime.now(),
                              );
                              await ref.read(inventoryRepositoryProvider).createItem(newItem);
                              ref.read(inventoryListStateProvider.notifier).loadFirstPage();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add part: $e')),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  isSaving = false;
                                });
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdjustStockDialog(
      BuildContext context,
      InventoryItem item,
      bool isAddition,
      ) {
    final qtyCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int getQty() => int.tryParse(qtyCtrl.text) ?? 0;
            void setQty(int val) {
              qtyCtrl.text = val.clamp(1, 999999).toString();
            }

            return AlertDialog(
              backgroundColor: kCard,
              title: Text(
                isAddition ? 'Add Stock' : 'Deduct Stock',
                style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(fontSize: 13, color: kMutedForeground),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isSaving
                              ? null
                              : () {
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
                            child: Icon(Icons.remove_rounded, color: kForeground),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: qtyCtrl,
                            enabled: !isSaving,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: kForeground,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator: (value) =>
                            (value == null ||
                                int.tryParse(value) == null ||
                                int.parse(value) <= 0)
                                ? 'Invalid'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: isSaving
                              ? null
                              : () {
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
                            child: Icon(Icons.add_rounded, color: kForeground),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [5, 10, 20]
                          .map(
                            (step) => OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () {
                                  final current = getQty();
                                  setStateDialog(() => setQty(current + step));
                                },
                          child: Text('+$step'),
                        ),
                      )
                          .toList(),
                    ),
                    if (!isAddition) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Current stock: ${item.stock} ${item.unit}',
                        style: TextStyle(fontSize: 12, color: kMutedForeground),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: kMutedForeground),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setStateDialog(() {
                              isSaving = true;
                            });
                            try {
                              final qty = getQty();

                              if (!isAddition && qty > item.stock) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Cannot deduct more than current stock (${item.stock} ${item.unit})',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final int newStock = isAddition
                                  ? item.stock + qty
                                  : (item.stock - qty).clamp(0, 999999).toInt();

                              await ref
                                  .read(inventoryRepositoryProvider)
                                  .updateStock(item.id!, newStock);
                              ref
                                  .read(inventoryListStateProvider.notifier)
                                  .loadFirstPage();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to adjust stock: $e')),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setStateDialog(() {
                                  isSaving = false;
                                });
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPartDialog(BuildContext context, InventoryItem item) {
    final screenContext = context;
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
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kCard,
              title: Text(
                'Edit Part',
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
                        controller: skuCtrl,
                        decoration: InputDecoration(
                          labelText: 'SKU (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
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
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isSaving = true;
                            });
                            try {
                              final name = nameCtrl.text.trim();
                              final existing = await ref.read(inventoryRepositoryProvider).findByName(name);
                              if (existing != null && existing.id != item.id) {
                                if (context.mounted) {
                                  setState(() {
                                    isSaving = false;
                                  });
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
                              );
                              await ref
                                  .read(inventoryRepositoryProvider)
                                  .updateItem(updatedItem);
                              ref.read(inventoryListStateProvider.notifier).loadFirstPage();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update part: $e')),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() {
                                  isSaving = false;
                                });
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          AppLocalizations.of(context)!.inventoryDeleteConfirmTitle,
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Text(
          AppLocalizations.of(context)!.inventoryDeleteConfirmBody(item.name),
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
                await ref
                    .read(inventoryRepositoryProvider)
                    .deleteItem(item.id!);
                ref.read(inventoryListStateProvider.notifier).loadFirstPage();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.inventoryDeleteSuccess,
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${AppLocalizations.of(context)!.inventoryDeleteError}: $e',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.inventoryDeletePart,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(filteredInventoryProvider);
    final lowStockItemsAsync = ref.watch(lowStockItemsProvider);
    final inventoryState = ref.watch(inventoryListStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPC = constraints.maxWidth > 900;
        if (isPC) {
          return _buildPCLayout(
            context,
            itemsAsync,
            lowStockItemsAsync,
            inventoryState,
          );
        } else {
          return _buildMobileLayout(
            context,
            itemsAsync,
            lowStockItemsAsync,
            inventoryState,
          );
        }
      },
    );
  }

  // ── PC Mode Layout (Data Table View) ───────────────────────────────────────
  Widget _buildPCLayout(
      BuildContext context,
      AsyncValue<List<InventoryItem>> itemsAsync,
      AsyncValue<List<InventoryItem>> lowStockItemsAsync,
      InventoryState inventoryState,
      ) {
    final items = itemsAsync.value ?? [];
    final lowStockItems = lowStockItemsAsync.value ?? [];
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kForeground,
                      ),
                    ),
                    Row(
                      children: [

                        InkWell(

                            onTap: ()async{
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
    const SnackBar(content: Text('Starting full resync...')),
    );

                              _handleRefresh();


    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Full resync completed!')),
    );
                              },



                            child: Icon(Icons.sync_rounded)),

                        SizedBox(width: 20,),
                        ElevatedButton.icon(
                          onPressed: () => _showAddPartDialog(context),
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.inventoryAddPart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
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
                          _tabButton(
                            0,
                            '${AppLocalizations.of(context)!.inventoryTabAll} (${items.length}${inventoryState.hasMore ? '+' : ''})',
                          ),
                          const SizedBox(width: 4),
                          _tabButton(
                            1,
                            '${AppLocalizations.of(context)!.inventoryTabLowStock} (${lowStockItems.length})',
                            isWarning: lowStockItems.isNotEmpty,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Search Bar
                    Expanded(
                      child: GarageSearchBar(
                        controller: _searchController,
                        hint: AppLocalizations.of(context)!.inventorySearchHint,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Table Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return itemsAsync.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: kRed),
                    ),
                  ),
                  data: (items) {
                    final lowStockItems = lowStockItemsAsync.value ?? [];
                    final displayItems = _getFilteredAndSortedItems(
                      items,
                      lowStockItems,
                    );
                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: kCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: kBorder),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth - 48,
                                      ),
                                      child: DataTable(
                                        showCheckboxColumn: false,
                                        headingRowColor:
                                        WidgetStateProperty.all(
                                          kMuted.withOpacity(0.4),
                                        ),
                                        headingTextStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kForeground,
                                        ),
                                        columnSpacing: 32,
                                        sortColumnIndex: _sortColumnIndex,
                                        sortAscending: _sortAscending,
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColName,
                                            ),
                                            onSort: (index, asc) =>
                                                _setSort(index, asc),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColSku,
                                            ),
                                            onSort: (index, asc) =>
                                                _setSort(index, asc),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColCategory,
                                            ),
                                            onSort: (index, asc) =>
                                                _setSort(index, asc),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColPurchase,
                                            ),
                                            numeric: true,
                                            onSort: (index, asc) =>
                                                _setSort(index, asc),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColSelling,
                                            ),
                                            numeric: true,
                                            onSort: (index, asc) =>
                                                _setSort(index, asc),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColStock,
                                            ),
                                            onSort: (index, asc) =>
                                                _setSort(index, asc),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColMinStock,
                                            ),
                                            numeric: true,
                                            onSort: (index, asc) =>
                                                _setSort(index, asc),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.inventoryColActions,
                                            ),
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
                                                        Icons
                                                            .inventory_2_rounded,
                                                        size: 16,
                                                        color: item.isLowStock
                                                            ? kRed
                                                            : kPrimary,
                                                      ),
                                                      const SizedBox(
                                                        width: 8,
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          item.name,
                                                          style:
                                                          const TextStyle(
                                                            fontWeight:
                                                            FontWeight
                                                                .w600,
                                                          ),
                                                          overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(Text(item.sku)),
                                              DataCell(Text(item.category)),
                                              DataCell(
                                                Text(
                                                  formatCurrency(
                                                    item.purchase,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formatCurrency(
                                                    item.selling,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: item.isLowStock
                                                        ? kRed.withOpacity(
                                                      0.1,
                                                    )
                                                        : Colors.transparent,
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                      6,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${item.stock} ${item.unit}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: item.isLowStock
                                                          ? kRed
                                                          : kForeground,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${item.minStock} ${item.unit}',
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .add_circle_outline_rounded,
                                                        size: 18,
                                                        color: kPrimary,
                                                      ),
                                                      onPressed: () =>
                                                          _showAdjustStockDialog(
                                                            context,
                                                            item,
                                                            true,
                                                          ),
                                                      tooltip: 'Add Stock',
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .remove_circle_outline_rounded,
                                                        size: 18,
                                                        color:
                                                        kMutedForeground,
                                                      ),
                                                      onPressed: () =>
                                                          _showAdjustStockDialog(
                                                            context,
                                                            item,
                                                            false,
                                                          ),
                                                      tooltip: 'Deduct Stock',
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.edit_rounded,
                                                        size: 18,
                                                        color:
                                                        kMutedForeground,
                                                      ),
                                                      onPressed: () =>
                                                          _showEditPartDialog(
                                                            context,
                                                            item,
                                                          ),
                                                      tooltip: 'Edit Part',
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 18,
                                                        color: kRed,
                                                      ),
                                                      onPressed: () =>
                                                          _showDeleteConfirmDialog(
                                                            context,
                                                            item,
                                                          ),
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
                                const Center(
                                  child: CircularProgressIndicator(),
                                )
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                  ),
                                  onPressed: () => ref
                                      .read(
                                    inventoryListStateProvider.notifier,
                                  )
                                      .loadMore(),
                                  child: const Text(
                                    'Load More',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                            ],
                          ],
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
              ? [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWarning && index == 1) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: kRed,
                  shape: BoxShape.circle,
                ),
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
  Widget _buildMobileLayout(
      BuildContext context,
      AsyncValue<List<InventoryItem>> itemsAsync,
      AsyncValue<List<InventoryItem>> lowStockItemsAsync,
      InventoryState inventoryState,
      ) {
    final items = itemsAsync.value ?? [];
    final lowStockItems = lowStockItemsAsync.value ?? [];
    final displayItems = _selectedTab == 0 ? items : lowStockItems;
    final showLowStockHeader = _selectedTab == 1 && lowStockItems.isNotEmpty;

    final int headerCount = showLowStockHeader ? 1 : 0;
    final int footerCount = inventoryState.hasMore ? 1 : 0;
    final int totalCount = headerCount + displayItems.length + footerCount;

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
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.inventoryTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<int>(
                          icon: Icon(
                            Icons.filter_list_rounded,
                            color: kMutedForeground,
                            size: 20,
                          ),
                          color: kCard,
                          onSelected: (val) =>
                              setState(() => _selectedTab = val),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 0,
                              child: Text(
                                'All Parts',
                                style: TextStyle(color: kForeground),
                              ),
                            ),
                            PopupMenuItem(
                              value: 1,
                              child: Text(
                                'Low Stock Only',
                                style: TextStyle(color: kForeground),
                              ),
                            ),
                          ],
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
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GarageSearchBar(
                  controller: _searchController,
                  hint: AppLocalizations.of(context)!.inventorySearchHint,
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
                final lowStockItems = lowStockItemsAsync.value ?? [];
                final displayItems = _selectedTab == 0
                    ? items
                    : lowStockItems;
                final showLowStockHeader =
                    _selectedTab == 1 && lowStockItems.isNotEmpty;

                final int headerCount = showLowStockHeader ? 1 : 0;
                final int footerCount = inventoryState.hasMore ? 1 : 0;
                final int totalCount =
                    headerCount + displayItems.length + footerCount;

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (showLowStockHeader && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${lowStockItems.length} items below minimum stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final itemIndex = index - headerCount;

                      if (itemIndex < displayItems.length) {
                        final item = displayItems[itemIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InventoryCard(
                            item: item,
                            onAdjustStock: _showAdjustStockDialog,
                            onEdit: _showEditPartDialog,
                            onDelete: _showDeleteConfirmDialog,
                          ),
                        );
                      }

                      if (inventoryState.isLoadMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: TextButton(
                            onPressed: () => ref
                                .read(inventoryListStateProvider.notifier)
                                .loadMore(),
                            child: const Text('Load More'),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
  final Function(BuildContext, InventoryItem) onDelete;

  const _InventoryCard({
    required this.item,
    required this.onAdjustStock,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GarageCard(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: kCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: kPrimary,
                  ),
                  title: Text(
                    'Add Stock',
                    style: TextStyle(color: kForeground),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onAdjustStock(context, item, true);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: kMutedForeground,
                  ),
                  title: Text(
                    'Deduct Stock',
                    style: TextStyle(color: kForeground),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onAdjustStock(context, item, false);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: kMutedForeground),
                  title: Text(
                    'Edit Part',
                    style: TextStyle(color: kForeground),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit(context, item);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: kRed,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.inventoryDeletePart,
                    style: const TextStyle(color: kRed),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete(context, item);
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.isLowStock
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 22,
              color: item.isLowStock ? kRed : kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: kForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: kMutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(fontSize: 10, color: kMutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Sell: ${formatCurrency(item.selling)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: kForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cost: ${formatCurrency(item.purchase)}',
                      style: TextStyle(fontSize: 11, color: kMutedForeground),
                    ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: item.isLowStock ? kRed : kForeground,
                ),
              ),
              const SizedBox(height: 4),
              if (item.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Low Stock',
                    style: TextStyle(
                      fontSize: 10,
                      color: kRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  'Min: ${item.minStock}',
                  style: TextStyle(fontSize: 10, color: kMutedForeground),
                ),
            ],
          ),
        ],
      ),
    );
  }
}