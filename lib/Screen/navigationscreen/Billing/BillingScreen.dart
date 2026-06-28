// lib/screens/billing/BillingScreen.dart
//
// Changes from previous version:
//  • Customer section: single TextField with auto-suggest overlay (existing)
//    + ability to type a new name (new customer saved automatically).
//    "Select Existing" toggle button removed.
//  • Vehicle fields (number, model, fuel-type) are now INSIDE the customer
//    card — no separate vehicle card / toggle.
//  • Add-Item sheet: vehicle model field added to BillingVehicle capture;
//    item sheet has improved layout with real-time total preview and
//    keyboard-dismissal-safe scrolling.

import 'package:collection/collection.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _formKey  = GlobalKey<FormState>();
  bool  _isSaving = false;

  // ── controllers ─────────────────────────────────────────────────────────────
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _saveInvoice() async {
    final draft = ref.read(invoiceDraftProvider);
    if (draft.customer == null) { _err('Customer zaroori hai'); return; }
    if (draft.items.isEmpty)   { _err('Kam se kam ek item add karo'); return; }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(invoiceDraftProvider.notifier);
      final custRepo  = ref.read(customerRepositoryProvider);
      final vehRepo   = ref.read(vehicleRepositoryProvider);
      final billRepo  = ref.read(billingRepositoryProvider);

      // Save new customer if needed
      BillingCustomer customer = draft.customer!;
      if (customer.id == null) {
        customer = await custRepo.createCustomer(customer);
        notifier.setCustomer(customer);
      }

      // Save new vehicle if needed
      BillingVehicle? vehicle = draft.vehicle;
      if (vehicle != null && vehicle.id == null) {
        vehicle = await vehRepo.createVehicle(
            vehicle.copyWith(customerId: customer.id!));
        notifier.setVehicle(vehicle);
      }

      final invoice = Invoice(
        invoiceNumber: '',
        customerId:    customer.id!,
        vehicleId:     vehicle?.id,
        invoiceDate:   draft.invoiceDate,
        subTotal:      draft.subTotal,
        discount:      draft.discount,
        gst:           draft.gst,
        grandTotal:    draft.grandTotal,
        paymentStatus: draft.paymentStatus,
        paymentMethod: draft.paymentMethod,
        notes:         _notesCtrl.text.trim(),
        createdAt:     DateTime.now(),
      );

      final saved = await billRepo.createInvoice(invoice, draft.items);
      ref.invalidate(invoiceListProvider);
      ref.invalidate(todaySummaryProvider);
      notifier.reset();

      if (mounted) context.push('/invoice/${saved.id}');
    } catch (e) {
      _err('Save failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  void _clearAll() {
    ref.read(invoiceDraftProvider.notifier).reset();
    _notesCtrl.clear();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final draft    = ref.watch(invoiceDraftProvider);
    final notifier = ref.read(invoiceDraftProvider.notifier);

    return Scaffold(
      backgroundColor: kBackground,
      body: Form(
        key: _formKey,
        child: Column(children: [

          _Header(onHistory: () => context.push('/InvoiceHistory')),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              children: [

                // ── Date ───────────────────────────────────────────────────
                _DateCard(date: draft.invoiceDate, onChanged: notifier.setDate),
                const SizedBox(height: 20),

                // ── Customer + Vehicle (unified) ───────────────────────────
                _sectionLabel('Customer & Vehicle'),
                const SizedBox(height: 10),
                _CustomerVehicleCard(
                  draft:    draft,
                  notifier: notifier,
                ),
                const SizedBox(height: 20),

                // ── Items ──────────────────────────────────────────────────
                _Label(
                  text: 'Items',
                  action: _AddItemButton(
                      onTap: () => _showItemSheet(notifier)),
                ),
                const SizedBox(height: 10),
                _ItemsSection(
                  items:    draft.items,
                  onRemove: notifier.removeItem,
                  onAdd:    () => _showItemSheet(notifier),
                ),
                const SizedBox(height: 20),

                // ── Summary ────────────────────────────────────────────────
                if (draft.items.isNotEmpty) ...[
                  _SummaryCard(
                    draft:      draft,
                    onDiscount: notifier.setDiscount,
                    onGst:      notifier.setGstPercent,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Payment ────────────────────────────────────────────────
                _PaymentCard(
                  draft:    draft,
                  onStatus: notifier.setPaymentStatus,
                  onMethod: notifier.setPaymentMethod,
                ),
                const SizedBox(height: 20),

                // ── Notes ──────────────────────────────────────────────────
                _NotesCard(ctrl: _notesCtrl),
              ],
            ),
          ),

          _SaveBar(
            isSaving: _isSaving,
            onSave:   _saveInvoice,
            onClear:  _clearAll,
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: kMutedForeground, letterSpacing: 0.3),
  );

  void _showItemSheet(InvoiceDraftNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(onAdd: notifier.addItem),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified Customer + Vehicle Card
// ─────────────────────────────────────────────────────────────────────────────

/// Single card that handles:
///  • Name field with auto-suggest overlay from existing customers
///  • Mobile / Email / Address (for new customers)
///  • Vehicle number, model, fuel-type — always visible once name is entered
// ─────────────────────────────────────────────────────────────────────────────
// _CustomerVehicleCard
//
// • Name, Mobile, Vehicle Number — teeno fields se auto-suggest chalti hai
// • Koi bhi field clear karo → baaki sab bhi khali ho jaate hain
// • Email + Address fields hata diye (sirf name + mobile rakha)
// • Suggest list mein naam + mobile + vehicle number dikhta hai
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerVehicleCard extends ConsumerStatefulWidget {
  final InvoiceDraft draft;
  final InvoiceDraftNotifier notifier;
  const _CustomerVehicleCard({required this.draft, required this.notifier});

  @override
  ConsumerState<_CustomerVehicleCard> createState() =>
      _CustomerVehicleCardState();
}

class _CustomerVehicleCardState extends ConsumerState<_CustomerVehicleCard> {

  // ── Focus nodes ─────────────────────────────────────────────────────────────
  final _nameFocus   = FocusNode();
  final _mobileFocus = FocusNode();
  final _vehNumFocus = FocusNode();

  // ── Controllers ─────────────────────────────────────────────────────────────
  final _nameCtrl     = TextEditingController();
  final _mobileCtrl   = TextEditingController();
  final _vehNumCtrl   = TextEditingController();
  final _vehModelCtrl = TextEditingController();

  // ── State ───────────────────────────────────────────────────────────────────
  List<BillingCustomer> _suggestions    = [];
  bool                  _showSuggestions = false;
  // Which field triggered the current suggest list
  _SuggestSource        _suggestSource  = _SuggestSource.name;
  bool                  _isExisting     = false;
  String?               _selectedFuel;

  List<BillingVehicle> _existingVehicles = [];
  BillingVehicle?      _selectedVehicle;

  @override
  void initState() {
    super.initState();
    final c = widget.draft.customer;
    if (c != null) {
      _nameCtrl.text   = c.name;
      _mobileCtrl.text = c.mobile;
      _isExisting      = c.id != null;
    }
    final v = widget.draft.vehicle;
    if (v != null) {
      _vehNumCtrl.text   = v.vehicleNumber;
      _vehModelCtrl.text = v.vehicleModel;
      _selectedFuel      = v.fuelType.isEmpty ? null : v.fuelType;
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose(); _mobileFocus.dispose(); _vehNumFocus.dispose();
    _nameCtrl.dispose(); _mobileCtrl.dispose();
    _vehNumCtrl.dispose(); _vehModelCtrl.dispose();
    super.dispose();
  }

  // ── Clear everything ────────────────────────────────────────────────────────

  void _clearAll() {
    _nameCtrl.clear();
    _mobileCtrl.clear();
    _vehNumCtrl.clear();
    _vehModelCtrl.clear();
    setState(() {
      _isExisting      = false;
      _showSuggestions = false;
      _suggestions     = [];
      _existingVehicles = [];
      _selectedVehicle  = null;
      _selectedFuel     = null;
    });
    widget.notifier.clearCustomer();
    widget.notifier.setVehicle(null);
  }

  // ── Search helper ────────────────────────────────────────────────────────────

  Future<void> _search(String query, _SuggestSource src) async {
    if (query.trim().isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    final repo   = ref.read(customerRepositoryProvider);
    final result = await repo.searchCustomers(query.trim());
    if (!mounted) return;
    setState(() {
      _suggestions     = result;
      _showSuggestions = result.isNotEmpty;
      _suggestSource   = src;
    });
  }

  // ── Field change handlers ───────────────────────────────────────────────────

  Future<void> _onNameChanged(String val) async {
    // User is typing — reset existing lock
    if (_isExisting) setState(() => _isExisting = false);
    widget.notifier.clearCustomer();
    _existingVehicles = [];
    _selectedVehicle  = null;
    _pushNewCustomerToDraft();
    await _search(val, _SuggestSource.name);
  }

  Future<void> _onMobileChanged(String val) async {
    if (_isExisting) setState(() => _isExisting = false);
    widget.notifier.clearCustomer();
    _existingVehicles = [];
    _selectedVehicle  = null;
    _pushNewCustomerToDraft();
    await _search(val, _SuggestSource.mobile);
  }

  Future<void> _onVehNumChanged(String val) async {
    _pushVehicleToDraft();
    // Search by vehicle number — results show customer who owns it
    if (val.trim().isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    final repo   = ref.read(vehicleRepositoryProvider);
    final vehs   = await repo.searchVehicles(val.trim());
    if (!mounted) return;
    // Convert matching vehicles → customers for the suggest list
    // We keep the vehicles in a side map so tapping fills both customer + vehicle
    _vehicleSuggestMap = { for (final v in vehs) v.customerId: v };
    final custRepo = ref.read(customerRepositoryProvider);
    final custs = await Future.wait(
      vehs.map((v) => custRepo.getCustomer(v.customerId)),
    );
    if (!mounted) return;
    setState(() {
      _suggestions     = custs.whereType<BillingCustomer>().toList();
      _showSuggestions = _suggestions.isNotEmpty;
      _suggestSource   = _SuggestSource.vehicleNum;
    });
  }

  // Side-map: customerId → BillingVehicle (used when suggest comes from vehicle search)
  Map<int, BillingVehicle> _vehicleSuggestMap = {};

  // ── Suggestion tapped ────────────────────────────────────────────────────────

  void _onSuggestionTapped(BillingCustomer c) async {
    setState(() {
      _isExisting      = true;
      _showSuggestions = false;
      _suggestions     = [];
    });
    _nameCtrl.text   = c.name;
    _mobileCtrl.text = c.mobile;
    _nameFocus.unfocus();
    _mobileFocus.unfocus();
    _vehNumFocus.unfocus();

    widget.notifier.setCustomer(c);
    widget.notifier.setVehicle(null);

    // If suggestion came from vehicle-number search, pre-fill that vehicle
    if (_suggestSource == _SuggestSource.vehicleNum &&
        c.id != null &&
        _vehicleSuggestMap.containsKey(c.id)) {
      final v = _vehicleSuggestMap[c.id]!;
      _vehNumCtrl.text   = v.vehicleNumber;
      _vehModelCtrl.text = v.vehicleModel;
      setState(() => _selectedFuel = v.fuelType.isEmpty ? null : v.fuelType);
      widget.notifier.setVehicle(v);
      setState(() {
        _selectedVehicle  = v;
        _existingVehicles = [v];
      });
    } else {
      _vehNumCtrl.clear();
      _vehModelCtrl.clear();
      setState(() { _selectedFuel = null; _selectedVehicle = null; });
    }

    // Load all vehicles for this customer
    if (c.id != null) {
      final repo = ref.read(vehicleRepositoryProvider);
      final vehs = await repo.getVehiclesForCustomer(c.id!);
      if (mounted) setState(() => _existingVehicles = vehs);
    }
  }

  // ── Draft push helpers ──────────────────────────────────────────────────────

  void _pushNewCustomerToDraft() {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      widget.notifier.setCustomer(BillingCustomer(
        name:      name,
        mobile:    _mobileCtrl.text.trim(),
        createdAt: DateTime.now(),
      ));
    }
  }

  void _pushVehicleToDraft() {
    final num  = _vehNumCtrl.text.trim().toUpperCase();
    if (num.isNotEmpty) {
      widget.notifier.setVehicle(BillingVehicle(
        customerId:    widget.draft.customer?.id ?? 0,
        vehicleNumber: num,
        vehicleModel:  _vehModelCtrl.text.trim(),
        fuelType:      _selectedFuel ?? '',
        createdAt:     DateTime.now(),
      ));
    } else {
      widget.notifier.setVehicle(null);
    }
  }

  void _onExistingVehicleSelected(BillingVehicle? v) {
    setState(() => _selectedVehicle = v);
    if (v != null) {
      _vehNumCtrl.text   = v.vehicleNumber;
      _vehModelCtrl.text = v.vehicleModel;
      setState(() => _selectedFuel = v.fuelType.isEmpty ? null : v.fuelType);
    } else {
      _vehNumCtrl.clear();
      _vehModelCtrl.clear();
      setState(() => _selectedFuel = null);
    }
    widget.notifier.setVehicle(v);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final anyInput = _nameCtrl.text.trim().isNotEmpty ||
        _mobileCtrl.text.trim().isNotEmpty;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Row: Name + clear button ──────────────────────────────────────
        _buildSearchField(
          ctrl:        _nameCtrl,
          focusNode:   _nameFocus,
          label:       'Customer Name',
          icon:        Icons.person_outline_rounded,
          onChanged:   _onNameChanged,
          showClear:   anyInput,
        ),

        if (_showSuggestions && _suggestSource == _SuggestSource.name)
          _buildSuggestionList(),

        // ── Mobile field ──────────────────────────────────────────────────
        const SizedBox(height: 12),
        _buildSearchField(
          ctrl:      _mobileCtrl,
          focusNode: _mobileFocus,
          label:     'Mobile Number',
          icon:      Icons.phone_outlined,
          type:      TextInputType.phone,
          onChanged: _onMobileChanged,
          showClear: false, // clear handled by name field X button
          enabled:   !_isExisting,
        ),

        if (_showSuggestions && _suggestSource == _SuggestSource.mobile)
          _buildSuggestionList(),

        // ── Existing customer info row ─────────────────────────────────────
        if (_isExisting) ...[
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded,
                    size: 12, color: Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Text('Existing customer',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32))),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _clearAll,
              child: const Text('Clear',
                  style: TextStyle(
                      fontSize: 12, color: kRed,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        ],

        // ── Vehicle divider ────────────────────────────────────────────────
        const SizedBox(height: 16),
        Row(children: [
          const Expanded(child: Divider(color: kBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.directions_car_outlined,
                  size: 14, color: kMutedForeground),
              SizedBox(width: 5),
              Text('Vehicle',
                  style: TextStyle(
                      fontSize: 11, color: kMutedForeground,
                      fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            ]),
          ),
          const Expanded(child: Divider(color: kBorder)),
        ]),
        const SizedBox(height: 14),

        // ── Saved vehicles dropdown (existing customer only) ───────────────
        if (_isExisting && _existingVehicles.isNotEmpty)
          _buildVehiclePicker(),

        // ── Vehicle Number ─────────────────────────────────────────────────
        _buildSearchField(
          ctrl:      _vehNumCtrl,
          focusNode: _vehNumFocus,
          label:     'Vehicle Number',
          icon:      Icons.pin_outlined,
          formatter: [_UpperCase()],
          onChanged: _onVehNumChanged,
          showClear: false,
        ),

        if (_showSuggestions && _suggestSource == _SuggestSource.vehicleNum)
          _buildSuggestionList(),

        const SizedBox(height: 12),

        // ── Vehicle Model ──────────────────────────────────────────────────
        _Field(
          ctrl:      _vehModelCtrl,
          label:     'Vehicle Model (e.g. Swift, Nexon)',
          icon:      Icons.directions_car_filled_outlined,
          onChanged: (_) => _pushVehicleToDraft(),
        ),
        const SizedBox(height: 12),

        // ── Fuel type chips ────────────────────────────────────────────────
        _buildFuelRow(),
      ]),
    );
  }

  // ── Reusable search-style field ────────────────────────────────────────────

  Widget _buildSearchField({
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required Future<void> Function(String) onChanged,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter> formatter = const [],
    bool showClear = false,
    bool enabled   = true,
  }) =>
      TextField(
        controller:      ctrl,
        focusNode:       focusNode,
        keyboardType:    type,
        inputFormatters: formatter,
        enabled:         enabled,
        onChanged:       onChanged,
        style: TextStyle(
            fontSize: 14,
            color: enabled ? kForeground : kMutedForeground),
        decoration: InputDecoration(
          labelText:  label,
          prefixIcon: Icon(icon, size: 18, color: kMutedForeground),
          suffixIcon: showClear
              ? GestureDetector(
            onTap: _clearAll,
            child: const Icon(Icons.close_rounded,
                size: 16, color: kMutedForeground),
          )
              : null,
          filled:    true,
          fillColor: enabled ? kMuted : kMuted.withOpacity(0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2)),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );

  // ── Suggestion list ─────────────────────────────────────────────────────────

  Widget _buildSuggestionList() => Container(
    margin: const EdgeInsets.only(top: 4),
    decoration: BoxDecoration(
      color:        kCard,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: kBorder),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(
      children: _suggestions.map((c) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onSuggestionTapped(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            // Avatar
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: kPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + mobile
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: kForeground)),
                  Text(c.mobile,
                      style: const TextStyle(
                          fontSize: 11, color: kMutedForeground)),
                  // If vehicle-number search, show vehicle too
                  if (_suggestSource == _SuggestSource.vehicleNum &&
                      c.id != null &&
                      _vehicleSuggestMap.containsKey(c.id))
                    Text(_vehicleSuggestMap[c.id]!.displayLabel,
                        style: const TextStyle(
                            fontSize: 11, color: kPrimary,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.north_west_rounded,
                size: 14, color: kMutedForeground),
          ]),
        ),
      )).toList(),
    ),
  );

  // ── Vehicle picker (existing customer's saved vehicles) ────────────────────

  Widget _buildVehiclePicker() {
    final safeValue = _existingVehicles
        .firstWhereOrNull((v) => v.id == _selectedVehicle?.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<BillingVehicle>(
        value: safeValue,
        isExpanded: true,
        hint: const Text('Saved vehicle chunein ya neeche naya daalo',
            style: TextStyle(color: kMutedForeground, fontSize: 12)),
        decoration: const InputDecoration(
          labelText: 'Saved Vehicles',
          prefixIcon: Icon(Icons.bookmark_outline_rounded,
              size: 18, color: kMutedForeground),
          filled: true, fillColor: kMuted,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: kBorder)),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: [
          const DropdownMenuItem<BillingVehicle>(
            value: null,
            child: Text('+ Naya vehicle',
                style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ),
          ..._existingVehicles.map((v) => DropdownMenuItem(
            value: v,
            child: Text(v.displayLabel, overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: _onExistingVehicleSelected,
      ),
    );
  }

  // ── Fuel type chips ─────────────────────────────────────────────────────────

  static const _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'];

  Widget _buildFuelRow() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Fuel Type',
          style: TextStyle(
              fontSize: 11, color: kMutedForeground,
              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _fuelTypes.map((t) {
          final sel = _selectedFuel == t;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFuel = sel ? null : t);
              _pushVehicleToDraft();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? kPrimary : kMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? kPrimary : kBorder),
              ),
              child: Text(t,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : kMutedForeground)),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

/// Which field triggered the current auto-suggest list
enum _SuggestSource { name, mobile, vehicleNum }

// ─────────────────────────────────────────────────────────────────────────────
// Remaining sub-widgets (unchanged structure, retained for completeness)
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onHistory;
  const _Header({required this.onHistory});

  @override
  Widget build(BuildContext context) => Container(
    color: kCard,
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 6,
      left: 4, right: 12, bottom: 12,
    ),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
        onPressed: () => context.pop(),
      ),
      const Expanded(
        child: Text('New Invoice',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800,
                color: kForeground, letterSpacing: -0.3)),
      ),
      GestureDetector(
        onTap: onHistory,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: kMuted, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.history_rounded, size: 15, color: kMutedForeground),
            SizedBox(width: 5),
            Text('History',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: kMutedForeground)),
          ]),
        ),
      ),
    ]),
  );
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateCard({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final p = await showDatePicker(
        context: context, initialDate: date,
        firstDate: DateTime(2020), lastDate: DateTime(2030),
      );
      if (p != null) onChanged(p);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.calendar_month_rounded,
              size: 18, color: kPrimary),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Invoice Date',
              style: TextStyle(
                  fontSize: 11, color: kMutedForeground,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(DateFormat('dd MMMM yyyy').format(date),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: kForeground)),
        ]),
        const Spacer(),
        const Icon(Icons.edit_calendar_rounded,
            size: 16, color: kMutedForeground),
      ]),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  final Widget? action;
  const _Label({required this.text, this.action});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(text,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: kMutedForeground, letterSpacing: 0.3)),
      if (action != null) action!,
    ],
  );
}

class _AddItemButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddItemButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: kPrimary, borderRadius: BorderRadius.circular(10)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_rounded, size: 14, color: Colors.white),
        SizedBox(width: 4),
        Text('Add Item',
            style: TextStyle(
                fontSize: 12, color: Colors.white,
                fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

// ── Items Section ──────────────────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  final List<InvoiceItem> items;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;
  const _ItemsSection(
      {required this.items, required this.onRemove, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: kMuted, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 22, color: kMutedForeground),
            ),
            const SizedBox(height: 10),
            const Text('Koi item nahi',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: kForeground)),
            const SizedBox(height: 4),
            const Text('Parts ya services add karne ke liye tap karo',
                style: TextStyle(fontSize: 12, color: kMutedForeground)),
          ]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: const Row(children: [
            Expanded(flex: 5,
                child: Text('ITEM', style: _hStyle)),
            SizedBox(width: 48,
                child: Text('QTY', textAlign: TextAlign.center, style: _hStyle)),
            Expanded(flex: 2,
                child: Text('RATE', textAlign: TextAlign.right, style: _hStyle)),
            Expanded(flex: 2,
                child: Text('TOTAL', textAlign: TextAlign.right, style: _hStyle)),
            SizedBox(width: 36),
          ]),
        ),
        ...List.generate(items.length, (i) => _ItemRow(
          item: items[i], isLast: i == items.length - 1,
          onRemove: () => onRemove(i),
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: kMuted,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${items.length} item${items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12, color: kMutedForeground,
                      fontWeight: FontWeight.w500)),
              Text(formatCurrency(
                  items.fold<double>(0, (s, e) => s + e.total).round()),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: kForeground)),
            ],
          ),
        ),
      ]),
    );
  }
}

const _hStyle = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w800,
    color: kMutedForeground, letterSpacing: 0.6);

class _ItemRow extends StatelessWidget {
  final InvoiceItem item;
  final bool isLast;
  final VoidCallback onRemove;
  const _ItemRow(
      {required this.item, required this.isLast, required this.onRemove});

  @override
  Widget build(BuildContext context) => Column(children: [
    const Divider(height: 1, color: kBorder, indent: 16, endIndent: 16),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          flex: 5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: kForeground),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: kMuted,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(item.unit,
                      style: const TextStyle(
                          fontSize: 10, color: kMutedForeground,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
        ),
        SizedBox(
          width: 48,
          child: Text(
            item.quantity % 1 == 0
                ? '${item.quantity.toInt()}'
                : item.quantity.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: kMutedForeground,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('₹${item.price.toInt()}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12, color: kMutedForeground)),
        ),
        Expanded(
          flex: 2,
          child: Text(formatCurrency(item.total.round()),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: kForeground)),
        ),
        SizedBox(
          width: 36,
          child: Center(
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 13, color: kRed),
              ),
            ),
          ),
        ),
      ]),
    ),
  ]);
}

// ── Summary Card ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatefulWidget {
  final InvoiceDraft draft;
  final ValueChanged<double> onDiscount;
  final ValueChanged<double> onGst;
  const _SummaryCard(
      {required this.draft, required this.onDiscount, required this.onGst});

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  final _discCtrl = TextEditingController();
  @override
  void dispose() { _discCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return _Card(
      child: Column(children: [
        _SummaryRow('Subtotal', formatCurrency(d.subTotal.round())),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GST',
                  style: TextStyle(fontSize: 13, color: kMutedForeground)),
              Row(
                children: [0.0, 5.0, 12.0, 18.0, 28.0].map((g) {
                  final sel = d.gstPercent == g;
                  return GestureDetector(
                    onTap: () => widget.onGst(g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : kMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${g.toInt()}%',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : kMutedForeground)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount (₹)',
                  style: TextStyle(fontSize: 13, color: kMutedForeground)),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _discCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: kForeground),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(color: kMutedForeground),
                    filled: true, fillColor: kMuted,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(
                        color: kMutedForeground, fontSize: 13),
                  ),
                  onChanged: (v) =>
                      widget.onDiscount(double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
        ),
        if (d.gst > 0)
          _SummaryRow('GST (${d.gstPercent.toInt()}%)',
              formatCurrency(d.gst.round()), subtle: true),
        if (d.discount > 0)
          _SummaryRow('Discount',
              '- ${formatCurrency(d.discount.round())}',
              valueColor: kGreen, subtle: true),
        const SizedBox(height: 8),
        Container(height: 1, color: kBorder),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Grand Total',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: kForeground)),
          Text(formatCurrency(d.grandTotal.round()),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: kPrimary, letterSpacing: -0.5)),
        ]),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool subtle;
  const _SummaryRow(this.label, this.value,
      {this.valueColor, this.subtle = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              fontSize: subtle ? 12 : 13, color: kMutedForeground)),
      Text(value,
          style: TextStyle(
              fontSize: subtle ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? kForeground)),
    ]),
  );
}

// ── Payment Card ───────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final InvoiceDraft draft;
  final ValueChanged<PaymentStatus> onStatus;
  final ValueChanged<PaymentMethod> onMethod;
  const _PaymentCard(
      {required this.draft, required this.onStatus, required this.onMethod});

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Payment',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: kForeground)),
      const SizedBox(height: 14),
      const Text('Status',
          style: TextStyle(
              fontSize: 11, color: kMutedForeground,
              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      Row(
        children: PaymentStatus.values.map((s) {
          final sel = draft.paymentStatus == s;
          final color = s == PaymentStatus.paid
              ? kGreen
              : s == PaymentStatus.partial
              ? kOrange
              : kRed;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onStatus(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.12) : kMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel ? color : Colors.transparent, width: 1.5),
                ),
                child: Text(s.label,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: sel ? color : kMutedForeground)),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),
      const Text('Method',
          style: TextStyle(
              fontSize: 11, color: kMutedForeground,
              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: PaymentMethod.values.map((m) {
          final sel = draft.paymentMethod == m;
          return GestureDetector(
            onTap: () => onMethod(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFE8F0FE) : kMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: sel ? kPrimary : Colors.transparent, width: 1.5),
              ),
              child: Text(m.label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: sel ? kPrimary : kMutedForeground)),
            ),
          );
        }).toList(),
      ),
    ]),
  );
}

// ── Notes Card ─────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final TextEditingController ctrl;
  const _NotesCard({required this.ctrl});

  @override
  Widget build(BuildContext context) => _Card(
    child: TextField(
      controller: ctrl,
      maxLines: 3,
      style: const TextStyle(fontSize: 13, color: kForeground),
      decoration: const InputDecoration(
        hintText: 'Notes ya remarks (optional)…',
        hintStyle: TextStyle(color: kMutedForeground),
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        prefixIcon: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.notes_rounded, size: 18, color: kMutedForeground),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    ),
  );
}

// ── Save Bar ───────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave, onClear;
  const _SaveBar(
      {required this.isSaving, required this.onSave, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 16, offset: const Offset(0, -4))],
    ),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    child: Row(children: [
      GestureDetector(
        onTap: onClear,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: kMuted, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: const Icon(Icons.refresh_rounded,
              color: kMutedForeground, size: 20),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: isSaving ? null : onSave,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            decoration: BoxDecoration(
              gradient: isSaving
                  ? null
                  : const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0288D1)]),
              color: isSaving ? kMuted : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSaving
                  ? []
                  : [BoxShadow(
                  color: kPrimary.withOpacity(0.35),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kPrimary))
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.save_alt_rounded,
                    color: Colors.white, size: 17),
                SizedBox(width: 8),
                Text('Save Invoice',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w800, letterSpacing: 0.2)),
              ]),
            ),
          ),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Item Sheet — improved
// ─────────────────────────────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final ValueChanged<InvoiceItem> onAdd;
  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl  = TextEditingController();
  final _qtyCtrl   = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  String _unit = 'pcs';

  static const _quickItems = [
    'Engine Oil', 'Oil Filter', 'Air Filter', 'Brake Pads',
    'Labour',     'Coolant',    'Spark Plugs', 'Wheel Alignment',
    'Chain Kit',  'Tyre',       'Battery',     'Clutch Plate',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _qtyCtrl.dispose(); _priceCtrl.dispose();
    super.dispose();
  }

  double get _total =>
      (double.tryParse(_qtyCtrl.text) ?? 0) *
          (double.tryParse(_priceCtrl.text) ?? 0);

  void _add() {
    final name  = _nameCtrl.text.trim();
    final qty   = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (name.isEmpty || qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sahi values fill karo'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    widget.onAdd(InvoiceItem.create(
        itemName: name, quantity: qty, unit: _unit, price: price));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Handle
              Center(child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: kBorder, borderRadius: BorderRadius.circular(2)),
              )),

              // Title row
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Item Add Karo',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: kForeground)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: kMuted, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: kMutedForeground),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Quick picks (horizontal scroll)
              const Text('Quick Pick',
                  style: TextStyle(
                      fontSize: 11, color: kMutedForeground,
                      fontWeight: FontWeight.w600, letterSpacing: 0.3)),
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
                      onTap: () =>
                          setState(() => _nameCtrl.text = _quickItems[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary : kMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel ? kPrimary : kBorder),
                        ),
                        child: Text(_quickItems[i],
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : kForeground)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Item name
              _Field(ctrl: _nameCtrl, label: 'Item Name',
                  icon: Icons.inventory_2_outlined,
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),

              // Qty + Unit row
              Row(children: [
                Expanded(
                  child: _Field(
                    ctrl: _qtyCtrl, label: 'Qty',
                    icon: Icons.numbers_rounded,
                    type: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      filled: true, fillColor: kMuted,
                      prefixIcon: Icon(Icons.straighten_rounded, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: kBorder)),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: ['pcs', 'litre', 'set', 'hr', 'kg', 'mtr']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Price
              _Field(
                ctrl: _priceCtrl, label: 'Price per unit (₹)',
                icon: Icons.currency_rupee_rounded,
                type: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Live total preview
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _total > 0
                    ? Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_qtyCtrl.text.isEmpty ? '0' : _qtyCtrl.text}'
                            ' $_unit  ×  '
                            '₹${_priceCtrl.text.isEmpty ? '0' : _priceCtrl.text}',
                        style: const TextStyle(
                            fontSize: 13, color: kMutedForeground),
                      ),
                      Text(formatCurrency(_total.round()),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: kPrimary)),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              // Add button
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Invoice mein Add Karo',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
      ),
    );
  }
}

// ── Shared primitives ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter> formatter;

  const _Field({
    required this.ctrl, required this.label, required this.icon,
    this.type = TextInputType.text,
    this.onChanged,
    this.formatter = const [],
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    inputFormatters: formatter,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 14, color: kForeground),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: kMutedForeground),
      filled: true, fillColor: kMuted,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 2)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}