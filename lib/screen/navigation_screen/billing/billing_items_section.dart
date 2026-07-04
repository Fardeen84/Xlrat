import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../core/Theme.dart';
import '../../../models/billing_model/InvoiceItem.dart';
import '../../../providers/billing_providers.dart';
import 'billing_shared.dart';
import '../../../models/InventoryItem.dart';
import '../../../providers/inventoryProvider.dart';

class BillingItemsSection extends ConsumerWidget {
  const BillingItemsSection({super.key});

  void _showItemSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddItemSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(invoiceDraftProvider);
    final items = draft.items;
    final notifier = ref.read(invoiceDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.billingItemsHeader,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMutedForeground, letterSpacing: 0.3),
            ),
            GestureDetector(
              onTap: () => _showItemSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.billingActionAddItem,
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          GestureDetector(
            onTap: () => _showItemSheet(context, ref),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.receipt_long_rounded, size: 22, color: kMutedForeground),
                  ),
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.billingNoItemsTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
                  const SizedBox(height: 4),
                  Text(AppLocalizations.of(context)!.billingNoItemsSubtitle, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 5, child: Text('ITEM', style: _hStyle)),
                      SizedBox(width: 48, child: Text('QTY', textAlign: TextAlign.center, style: _hStyle)),
                      Expanded(flex: 2, child: Text('RATE', textAlign: TextAlign.right, style: _hStyle)),
                      Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: _hStyle)),
                      SizedBox(width: 36),
                    ],
                  ),
                ),
                ...List.generate(
                  items.length,
                  (i) => _ItemRow(
                    item: items[i],
                    isLast: i == items.length - 1,
                    onRemove: () => notifier.removeItem(i),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: kMuted,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${items.length} item${items.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, color: kMutedForeground, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        formatCurrency(items.fold<double>(0, (s, e) => s + e.total).round()),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

const _hStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6);

class _ItemRow extends StatelessWidget {
  final InvoiceItem item;
  final bool isLast;
  final VoidCallback onRemove;
  const _ItemRow({required this.item, required this.isLast, required this.onRemove});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Divider(height: 1, color: kBorder, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          item.unit,
                          style: const TextStyle(fontSize: 10, color: kMutedForeground, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    item.quantity % 1 == 0 ? '${item.quantity.toInt()}' : item.quantity.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: kMutedForeground, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    '₹${item.price.toInt()}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: kMutedForeground),
                  ),
                  flex: 2,
                ),
                Expanded(
                  child: Text(
                    formatCurrency(item.total.round()),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground),
                  ),
                  flex: 2,
                ),
                SizedBox(
                  width: 36,
                  child: Center(
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded, size: 13, color: kRed),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet();

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _nameFocusNode = FocusNode();
  String _unit = 'pcs';
  int? _selectedProductId;

  static const _quickItems = [
    'Engine Oil',
    'Oil Filter',
    'Air Filter',
    'Brake Pads',
    'Labour',
    'Coolant',
    'Spark Plugs',
    'Wheel Alignment',
    'Chain Kit',
    'Tyre',
    'Battery',
    'Clutch Plate',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  double get _total => (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0);

  void _add() {
    final name = _nameCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (name.isEmpty || qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sahi values fill karo'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    ref.read(invoiceDraftProvider.notifier).addItem(
          InvoiceItem.create(
            productId: _selectedProductId,
            itemName: name,
            quantity: qty,
            unit: _unit,
            price: price,
          ),
        );

    if (_selectedProductId != null) {
      final inventory = ref.read(inventoryListProvider).value ?? [];
      final match = inventory.where((item) => item.id == _selectedProductId);
      if (match.isNotEmpty) {
        final item = match.first;
        final newStock = (item.stock - qty.toInt()).clamp(0, 999999);
        ref.read(inventoryRepositoryProvider).updateStock(_selectedProductId!, newStock);
        ref.invalidate(inventoryListProvider);
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryListProvider);
    final inventory = inventoryAsync.value ?? [];
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Item Add Karo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kForeground)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close_rounded, size: 16, color: kMutedForeground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick picks (horizontal scroll)
            const Text(
              'Quick Pick',
              style: TextStyle(fontSize: 11, color: kMutedForeground, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _nameCtrl.text == _quickItems[i];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _nameCtrl.text = _quickItems[i];
                      _selectedProductId = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : kMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? kPrimary : kBorder),
                      ),
                      child: Text(
                        _quickItems[i],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : kForeground),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Item name with Autocomplete
            Autocomplete<InventoryItem>(
              textEditingController: _nameCtrl,
              focusNode: _nameFocusNode,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<InventoryItem>.empty();
                }
                return inventory.where((item) => item.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              displayStringForOption: (InventoryItem option) => option.name,
              onSelected: (InventoryItem selection) {
                setState(() {
                  _nameCtrl.text = selection.name;
                  _priceCtrl.text = selection.selling.toString();
                  _unit = selection.unit;
                  _selectedProductId = selection.id;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return BillingField(
                  ctrl: controller,
                  label: 'Item Name',
                  icon: Icons.inventory_2_outlined,
                  onChanged: (val) {
                    setState(() {
                      _selectedProductId = null;
                    });
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 40,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: index == options.length - 1 ? Colors.transparent : kBorder,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SKU: ${option.sku} • Stock: ${option.stock} ${option.unit}',
                                          style: const TextStyle(fontSize: 11, color: kMutedForeground),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${option.selling}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Qty + Unit row
            Row(
              children: [
                Expanded(
                  child: BillingField(
                    ctrl: _qtyCtrl,
                    label: 'Qty',
                    icon: Icons.numbers_rounded,
                    type: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      filled: true,
                      fillColor: kMuted,
                      prefixIcon: Icon(Icons.straighten_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: kBorder)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: ['pcs', 'litre', 'set', 'hr', 'kg', 'mtr'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price
            BillingField(
              ctrl: _priceCtrl,
              label: 'Price per unit (₹)',
              icon: Icons.currency_rupee_rounded,
              type: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Live total preview
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _total > 0
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_qtyCtrl.text.isEmpty ? '0' : _qtyCtrl.text} $_unit  ×  ₹${_priceCtrl.text.isEmpty ? '0' : _priceCtrl.text}',
                            style: const TextStyle(fontSize: 13, color: kMutedForeground),
                          ),
                          Text(
                            formatCurrency(_total.round()),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Add button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _add,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Invoice mein Add Karo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
