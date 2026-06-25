
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../Models/Billing model/BillingCustomer.dart';
import '../../../Models/Billing model/BillingVehicle.dart';
import '../../../Models/Billing model/InvoiceItem.dart';
import '../../../Models/Billing model/invoice.dart';
import '../../../Providers/billing_providers.dart';

import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // ── Controllers for new customer fields ──────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  // ── Controllers for new vehicle fields ───────────────────────────────────
  final _vehNumberCtrl = TextEditingController();
  final _vehBrandCtrl = TextEditingController();
  final _vehModelCtrl = TextEditingController();
  final _vehFuelCtrl = TextEditingController();

  // ── Notes ─────────────────────────────────────────────────────────────────
  final _notesCtrl = TextEditingController();

  // ── UI state for customer / vehicle entry mode ────────────────────────────
  bool _useExistingCustomer = false;
  bool _useExistingVehicle = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    _vehNumberCtrl.dispose();
    _vehBrandCtrl.dispose();
    _vehModelCtrl.dispose();
    _vehFuelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Save flow ─────────────────────────────────────────────────────────────
  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final draft = ref.read(invoiceDraftProvider);

    if (draft.customer == null && !_useExistingCustomer) {
      if (_nameCtrl.text.trim().isEmpty || _mobileCtrl.text.trim().isEmpty) {
        _showError('Customer name and mobile are required.');
        return;
      }
    }
    if (draft.customer == null) {
      _showError('Please select or enter a customer.');
      return;
    }
    if (draft.items.isEmpty) {
      _showError('Add at least one invoice item.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(invoiceDraftProvider.notifier);
      final customerRepo = ref.read(customerRepositoryProvider);
      final vehicleRepo = ref.read(vehicleRepositoryProvider);
      final billingRepo = ref.read(billingRepositoryProvider);

      // 1. Save customer if new
      BillingCustomer customer = draft.customer!;
      if (customer.id == null) {
        customer = await customerRepo.createCustomer(customer);
        notifier.setCustomer(customer);
      }

      // 2. Save vehicle if provided and new
      BillingVehicle? vehicle = draft.vehicle;
      if (vehicle != null && vehicle.id == null) {
        vehicle = await vehicleRepo.createVehicle(
          vehicle.copyWith(customerId: customer.id!),
        );
        notifier.setVehicle(vehicle);
      }

      // 3. Build Invoice object
      final now = DateTime.now();
      final invoice = Invoice(
        invoiceNumber: '',
        customerId: customer.id!,
        vehicleId: vehicle?.id,
        invoiceDate: draft.invoiceDate,
        subTotal: draft.subTotal,
        discount: draft.discount,
        gst: draft.gst,
        grandTotal: draft.grandTotal,
        paymentStatus: draft.paymentStatus,
        paymentMethod: draft.paymentMethod,
        notes: _notesCtrl.text.trim(),
        createdAt: now,
      );

      // 4. Save invoice + items atomically
      final saved = await billingRepo.createInvoice(invoice, draft.items);

      // 5. Refresh providers
      ref.invalidate(invoiceListProvider);
      ref.invalidate(todaySummaryProvider);

      // 6. Reset draft
      notifier.reset();

      // 7. Navigate to invoice preview
      if (mounted) {
        context.go('/invoice/${saved.id}');
      }
    } catch (e) {
      _showError('Failed to save invoice: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: kRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(invoiceDraftProvider);
    final notifier = ref.read(invoiceDraftProvider.notifier);

    return Scaffold(
      backgroundColor: kBackground,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── App Bar ───────────────────────────────────────────────────
            Container(
              color: kCard,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 4,
                right: 16,
                bottom: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
                    onPressed: () => context.go('/dashboard'),
                  ),
                  const Expanded(
                    child: Text('Create Invoice',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kForeground)),
                  ),
                  TextButton(
                    onPressed: () => context.go('/invoice-history'),
                    child: const Text('History', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // ── Invoice Date ──────────────────────────────────────
                  _InvoiceDatePicker(
                    date: draft.invoiceDate,
                    onChanged: notifier.setDate,
                  ),
                  const SizedBox(height: 12),

                  // ── Customer Section ──────────────────────────────────
                  _SectionTitle(
                    title: 'Customer',
                    trailing: TextButton(
                      onPressed: () => setState(() => _useExistingCustomer = !_useExistingCustomer),
                      child: Text(
                        _useExistingCustomer ? '+ New Customer' : 'Select Existing',
                        style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_useExistingCustomer)
                    _CustomerPicker(
                      selected: draft.customer,
                      onSelected: (c) {
                        notifier.setCustomer(c);
                        notifier.setVehicle(null);
                      },
                    )
                  else
                    _NewCustomerForm(
                      nameCtrl: _nameCtrl,
                      mobileCtrl: _mobileCtrl,
                      emailCtrl: _emailCtrl,
                      addressCtrl: _addressCtrl,
                      gstCtrl: _gstCtrl,
                      onChanged: () {
                        if (_nameCtrl.text.isNotEmpty && _mobileCtrl.text.isNotEmpty) {
                          notifier.setCustomer(BillingCustomer(
                            name: _nameCtrl.text.trim(),
                            mobile: _mobileCtrl.text.trim(),
                            email: _emailCtrl.text.trim(),
                            address: _addressCtrl.text.trim(),
                            gstNumber: _gstCtrl.text.trim(),
                            createdAt: DateTime.now(),
                          ));
                        }
                      },
                    ),
                  const SizedBox(height: 12),

                  // ── Vehicle Section ───────────────────────────────────
                  if (draft.customer != null) ...[
                    _SectionTitle(
                      title: 'Vehicle',
                      trailing: draft.customer?.id != null
                          ? TextButton(
                        onPressed: () => setState(() => _useExistingVehicle = !_useExistingVehicle),
                        child: Text(
                          _useExistingVehicle ? '+ New Vehicle' : 'Select Existing',
                          style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 8),
                    if (_useExistingVehicle && draft.customer?.id != null)
                      _VehiclePicker(
                        customerId: draft.customer!.id!,
                        selected: draft.vehicle,
                        onSelected: notifier.setVehicle,
                      )
                    else
                      _NewVehicleForm(
                        numberCtrl: _vehNumberCtrl,
                        brandCtrl: _vehBrandCtrl,
                        modelCtrl: _vehModelCtrl,
                        fuelCtrl: _vehFuelCtrl,
                        onChanged: () {
                          if (_vehNumberCtrl.text.isNotEmpty) {
                            notifier.setVehicle(BillingVehicle(
                              customerId: draft.customer?.id ?? 0,
                              vehicleNumber: _vehNumberCtrl.text.trim().toUpperCase(),
                              vehicleBrand: _vehBrandCtrl.text.trim(),
                              vehicleModel: _vehModelCtrl.text.trim(),
                              fuelType: _vehFuelCtrl.text.trim(),
                              createdAt: DateTime.now(),
                            ));
                          }
                        },
                      ),
                    const SizedBox(height: 12),
                  ],

                  // ── Invoice Items ─────────────────────────────────────
                  _SectionTitle(
                    title: 'Invoice Items',
                    trailing: GestureDetector(
                      onTap: () => _showAddItemSheet(context, notifier),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Add Item', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (draft.items.isEmpty)
                    GarageCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 36, color: kMutedForeground.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              const Text('No items added yet', style: TextStyle(color: kMutedForeground, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    _ItemsTable(
                      items: draft.items,
                      onRemove: (i) => notifier.removeItem(i),
                    ),
                  const SizedBox(height: 12),

                  // ── Summary Card ──────────────────────────────────────
                  _BillSummaryCard(
                    draft: draft,
                    onDiscountChanged: notifier.setDiscount,
                    onGstChanged: notifier.setGstPercent,
                  ),
                  const SizedBox(height: 12),

                  // ── Payment ───────────────────────────────────────────
                  _PaymentSection(
                    draft: draft,
                    onStatusChanged: notifier.setPaymentStatus,
                    onMethodChanged: notifier.setPaymentMethod,
                  ),
                  const SizedBox(height: 12),

                  // ── Notes ─────────────────────────────────────────────
                  GarageCard(
                    child: TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Actions ────────────────────────────────────────────
            Container(
              color: kCard,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveInvoice,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_isSaving ? 'Saving…' : 'Save Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      shadowColor: kPrimary.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(invoiceDraftProvider.notifier).reset();
                      _nameCtrl.clear(); _mobileCtrl.clear();
                      _emailCtrl.clear(); _addressCtrl.clear(); _gstCtrl.clear();
                      _vehNumberCtrl.clear(); _vehBrandCtrl.clear();
                      _vehModelCtrl.clear(); _vehFuelCtrl.clear();
                      _notesCtrl.clear();
                      setState(() { _useExistingCustomer = false; _useExistingVehicle = false; });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: kMutedForeground),
                    label: const Text('Clear', style: TextStyle(color: kMutedForeground)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: kBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Item Bottom Sheet ─────────────────────────────────────────────────
  void _showAddItemSheet(BuildContext context, InvoiceDraftNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(onAdd: (item) {
        notifier.addItem(item);
      }),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Invoice Date Picker ────────────────────────────────────────────────────────

class _InvoiceDatePicker extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _InvoiceDatePicker({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GarageCard(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: kPrimary),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Invoice Date', style: TextStyle(fontSize: 11, color: kMutedForeground)),
            Text(DateFormat('dd MMM yyyy').format(date),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kForeground)),
          ]),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: kMutedForeground),
        ],
      ),
    );
  }
}

// ── New Customer Form ──────────────────────────────────────────────────────────

class _NewCustomerForm extends StatelessWidget {
  final TextEditingController nameCtrl, mobileCtrl, emailCtrl, addressCtrl, gstCtrl;
  final VoidCallback onChanged;
  const _NewCustomerForm({
    required this.nameCtrl, required this.mobileCtrl, required this.emailCtrl,
    required this.addressCtrl, required this.gstCtrl, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GarageCard(
      child: Column(children: [
        _Field(ctrl: nameCtrl, label: 'Customer Name *', onChanged: (_) => onChanged(),
            inputAction: TextInputAction.next),
        const SizedBox(height: 10),
        _Field(ctrl: mobileCtrl, label: 'Mobile Number *', keyboardType: TextInputType.phone,
            onChanged: (_) => onChanged(), inputAction: TextInputAction.next),
        const SizedBox(height: 10),
        _Field(ctrl: emailCtrl, label: 'Email', keyboardType: TextInputType.emailAddress,
            onChanged: (_) => onChanged(), inputAction: TextInputAction.next),
        const SizedBox(height: 10),
        _Field(ctrl: addressCtrl, label: 'Address', onChanged: (_) => onChanged(), inputAction: TextInputAction.next),
        const SizedBox(height: 10),
        _Field(ctrl: gstCtrl, label: 'GST Number', onChanged: (_) => onChanged(), inputAction: TextInputAction.done),
      ]),
    );
  }
}

// ── Customer Picker (existing) ────────────────────────────────────────────────

class _CustomerPicker extends ConsumerWidget {
  final BillingCustomer? selected;
  final ValueChanged<BillingCustomer> onSelected;
  const _CustomerPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    return customersAsync.when(
      loading: () => const GarageCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => GarageCard(child: Text('Error: $e')),
      data: (customers) {
        if (customers.isEmpty) {
          return const GarageCard(child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('No customers yet. Enter new customer details.', style: TextStyle(color: kMutedForeground)),
          ));
        }
        return GarageCard(
          child: DropdownButtonFormField<BillingCustomer>(
            value: selected,
            decoration: const InputDecoration(
              labelText: 'Select Customer',
              border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
            ),
            items: customers.map((c) => DropdownMenuItem(
              value: c,
              child: Text('${c.name} · ${c.mobile}'),
            )).toList(),
            onChanged: (c) { if (c != null) onSelected(c); },
          ),
        );
      },
    );
  }
}

// ── New Vehicle Form ───────────────────────────────────────────────────────────

class _NewVehicleForm extends StatelessWidget {
  final TextEditingController numberCtrl, brandCtrl, modelCtrl, fuelCtrl;
  final VoidCallback onChanged;
  const _NewVehicleForm({
    required this.numberCtrl, required this.brandCtrl, required this.modelCtrl,
    required this.fuelCtrl, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GarageCard(
      child: Column(children: [
        _Field(ctrl: numberCtrl, label: 'Vehicle Number *', onChanged: (_) => onChanged(),
            inputAction: TextInputAction.next,
            formatter: [UpperCaseTextFormatter()]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Field(ctrl: brandCtrl, label: 'Brand', onChanged: (_) => onChanged(), inputAction: TextInputAction.next)),
          const SizedBox(width: 10),
          Expanded(child: _Field(ctrl: modelCtrl, label: 'Model', onChanged: (_) => onChanged(), inputAction: TextInputAction.next)),
        ]),
        const SizedBox(height: 10),
        _Field(ctrl: fuelCtrl, label: 'Fuel Type', onChanged: (_) => onChanged(), inputAction: TextInputAction.done),
      ]),
    );
  }
}

// ── Vehicle Picker ────────────────────────────────────────────────────────────

class _VehiclePicker extends ConsumerWidget {
  final int customerId;
  final BillingVehicle? selected;
  final ValueChanged<BillingVehicle?> onSelected;
  const _VehiclePicker({required this.customerId, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesForCustomerProvider(customerId));
    return vehiclesAsync.when(
      loading: () => const GarageCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => GarageCard(child: Text('Error: $e')),
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return const GarageCard(child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('No vehicles for this customer.', style: TextStyle(color: kMutedForeground)),
          ));
        }
        return GarageCard(
          child: DropdownButtonFormField<BillingVehicle>(
            value: selected,
            decoration: const InputDecoration(
              labelText: 'Select Vehicle',
              border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero,
            ),
            items: vehicles.map((v) => DropdownMenuItem(
              value: v,
              child: Text(v.displayLabel),
            )).toList(),
            onChanged: (v) => onSelected(v),
          ),
        );
      },
    );
  }
}

// ── Items Table ───────────────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final List<InvoiceItem> items;
  final ValueChanged<int> onRemove;
  const _ItemsTable({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 0.8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header row
          Container(
            color: kMuted,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('ITEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
                SizedBox(width: 44, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
                Expanded(flex: 2, child: Text('RATE', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
                SizedBox(width: 32),
              ],
            ),
          ),
          ...List.generate(items.length, (i) {
            final item = items[i];
            return Column(children: [
              const Divider(height: 1, color: kBorder),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.itemName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kForeground)),
                      Text(item.unit, style: const TextStyle(fontSize: 10, color: kMutedForeground)),
                    ])),
                    SizedBox(width: 44, child: Text('${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: kMutedForeground))),
                    Expanded(flex: 2, child: Text('₹${item.price.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: kMutedForeground))),
                    Expanded(flex: 2, child: Text('₹${item.total.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kForeground))),
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 14, color: kRed),
                        onPressed: () => onRemove(i),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ]);
          }),
        ],
      ),
    );
  }
}

// ── Bill Summary Card ─────────────────────────────────────────────────────────

class _BillSummaryCard extends StatefulWidget {
  final InvoiceDraft draft;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<double> onGstChanged;
  const _BillSummaryCard({required this.draft, required this.onDiscountChanged, required this.onGstChanged});

  @override
  State<_BillSummaryCard> createState() => _BillSummaryCardState();
}

class _BillSummaryCardState extends State<_BillSummaryCard> {
  final _discountCtrl = TextEditingController();

  @override
  void dispose() { _discountCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return GarageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', formatCurrency(d.subTotal.round())),

          // Discount
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount (₹)', style: TextStyle(fontSize: 13, color: kMutedForeground)),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      isDense: true,
                    ),
                    onChanged: (v) => widget.onDiscountChanged(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
          ),

          // GST
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GST %', style: TextStyle(fontSize: 13, color: kMutedForeground)),
                Row(children: [0.0, 5.0, 12.0, 18.0, 28.0].map((g) {
                  final isSelected = d.gstPercent == g;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () => widget.onGstChanged(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary : kMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${g.toInt()}%', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : kMutedForeground,
                        )),
                      ),
                    ),
                  );
                }).toList()),
              ],
            ),
          ),

          _summaryRow('GST (${d.gstPercent.toInt()}%)', formatCurrency(d.gst.round())),
          if (d.discount > 0)
            _summaryRow('Discount', '- ${formatCurrency(d.discount.round())}'),

          const Divider(color: kBorder),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kForeground)),
            Text(formatCurrency(d.grandTotal.round()),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary)),
          ]),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: kMutedForeground)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kForeground)),
    ]),
  );
}

// ── Payment Section ────────────────────────────────────────────────────────────

class _PaymentSection extends StatelessWidget {
  final InvoiceDraft draft;
  final ValueChanged<PaymentStatus> onStatusChanged;
  final ValueChanged<PaymentMethod> onMethodChanged;
  const _PaymentSection({required this.draft, required this.onStatusChanged, required this.onMethodChanged});

  @override
  Widget build(BuildContext context) {
    return GarageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
          const SizedBox(height: 12),
          const Text('Status', style: TextStyle(fontSize: 12, color: kMutedForeground)),
          const SizedBox(height: 8),
          Row(children: PaymentStatus.values.map((s) {
            final sel = draft.paymentStatus == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onStatusChanged(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? kPrimary : kMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(s.label, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : kMutedForeground,
                  )),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),
          const Text('Method', style: TextStyle(fontSize: 12, color: kMutedForeground)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: PaymentMethod.values.map((m) {
            final sel = draft.paymentMethod == m;
            return GestureDetector(
              onTap: () => onMethodChanged(m),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? kPrimary : kMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(m.label, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : kMutedForeground,
                )),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }
}

// ── Add Item Bottom Sheet ──────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final ValueChanged<InvoiceItem> onAdd;
  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  String _unit = 'pcs';

  @override
  void dispose() { _nameCtrl.dispose(); _qtyCtrl.dispose(); _priceCtrl.dispose(); super.dispose(); }

  void _add() {
    final name = _nameCtrl.text.trim();
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (name.isEmpty || qty <= 0 || price <= 0) return;
    widget.onAdd(InvoiceItem.create(
      itemName: name, quantity: qty, unit: _unit, price: price,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Add Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kForeground)),
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),
        _Field(ctrl: _nameCtrl, label: 'Item Name *', inputAction: TextInputAction.next),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Field(ctrl: _qtyCtrl, label: 'Qty *', keyboardType: TextInputType.number, inputAction: TextInputAction.next)),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(
            value: _unit,
            decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
            items: ['pcs', 'litre', 'set', 'hr', 'kg', 'mtr']
                .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
          )),
        ]),
        const SizedBox(height: 10),
        _Field(ctrl: _priceCtrl, label: 'Price (₹) *', keyboardType: TextInputType.number, inputAction: TextInputAction.done),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _add,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }
}

// ── Reusable text field ────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType keyboardType;
  final TextInputAction inputAction;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter> formatter;

  const _Field({
    required this.ctrl,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.onChanged,
    this.formatter = const [],
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textInputAction: inputAction,
      inputFormatters: formatter,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newV) =>
      newV.copyWith(text: newV.text.toUpperCase());
}