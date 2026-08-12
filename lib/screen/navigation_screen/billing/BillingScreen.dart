// lib/screen/navigation_screen/billing/BillingScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../models/billing_model/invoice.dart';
import '../../../providers/billing_providers.dart';
import '../../../providers/InvoicePdfService.dart';
import '../../../core/Theme.dart';

import '../../../widgets/LabourCard.dart';
import 'billing_customer_section.dart';
import 'billing_vehicle_section.dart';
import 'billing_items_section.dart';
import 'billing_summary_section.dart';
import 'billing_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

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
    if (draft.customer == null) {
      _err(AppLocalizations.of(context)!.billingErrorCustomerRequired);
      return;
    }
    if (draft.items.isEmpty) {
      _err(AppLocalizations.of(context)!.billingErrorItemRequired);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(invoiceDraftProvider.notifier);
      final custRepo = ref.read(customerRepositoryProvider);
      final vehRepo = ref.read(vehicleRepositoryProvider);
      final billRepo = ref.read(billingRepositoryProvider);

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
          vehicle.copyWith(customerId: customer.id!),
        );
        notifier.setVehicle(vehicle);
      }

      final isEditing = draft.invoiceId != null;

      final invoice = Invoice(
        id: draft.invoiceId,
        invoiceNumber: draft.invoiceNumber,
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
        createdAt: DateTime.now(),
      );

      final saved = isEditing
          ? await billRepo.updateInvoice(invoice, draft.items)
          : await billRepo.createInvoice(invoice, draft.items);
      ref.invalidate(invoicesListStateProvider);
      ref.invalidate(todaySummaryProvider);
      notifier.reset();
      _notesCtrl.clear();

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
    final draft = ref.watch(invoiceDraftProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPC = constraints.maxWidth > 1100;
            if (isPC) {
              return _buildPCLayout(context, draft);
            } else {
              return _buildMobileLayout(context, draft);
            }
          },
        ),
      ),
    );
  }

  // ── PC Mode Layout (Two Panel Split) ────────────────────────────────────────
  Widget _buildPCLayout(BuildContext context, InvoiceDraft draft) {
    final invoice = Invoice(
      id: draft.invoiceId,
      invoiceNumber: draft.invoiceNumber.isNotEmpty
          ? draft.invoiceNumber
          : 'DRAFT-XXXX',
      customerId: draft.customer?.id ?? '',
      customer: draft.customer,
      vehicleId: draft.vehicle?.id,
      vehicle: draft.vehicle,
      invoiceDate: draft.invoiceDate,
      subTotal: draft.subTotal,
      discount: draft.discount,
      gst: draft.gst,
      grandTotal: draft.grandTotal,
      paymentStatus: draft.paymentStatus,
      paymentMethod: draft.paymentMethod,
      notes: _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
      items: draft.items,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Panel - Scrollable Form
        Expanded(
          flex: 11,
          child: Column(
            children: [
              _Header(onHistory: () => context.push('/InvoiceHistory')),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                  children: [
                    _DateCard(
                      date: draft.invoiceDate,
                      onChanged: ref
                          .read(invoiceDraftProvider.notifier)
                          .setDate,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Customer & Vehicle'),
                    const SizedBox(height: 10),
                    BillingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BillingCustomerSection(),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Divider(color: kBorder)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_car_outlined,
                                      size: 14,
                                      color: kMutedForeground,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Vehicle',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kMutedForeground,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(child: Divider(color: kBorder)),
                            ],
                          ),
                          SizedBox(height: 14),
                          BillingVehicleSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const BillingItemsSection(),
                    const SizedBox(height: 20),
                    const LabourCard(), // ← ye naya add karo
                    const SizedBox(height: 20),
                    if (draft.items.isNotEmpty) ...[
                      const BillingSummarySection(),
                      const SizedBox(height: 20),
                    ],
                    _PaymentCard(
                      draft: draft,
                      onStatus: ref
                          .read(invoiceDraftProvider.notifier)
                          .setPaymentStatus,
                      onMethod: ref
                          .read(invoiceDraftProvider.notifier)
                          .setPaymentMethod,
                    ),
                    const SizedBox(height: 20),
                    _NotesCard(ctrl: _notesCtrl),
                  ],
                ),
              ),
              _SaveBar(
                isSaving: _isSaving,
                onSave: _saveInvoice,
                onClear: _clearAll,
              ),
            ],
          ),
        ),
        // Divider
        Container(width: 1, color: kBorder),
        // Right Panel - Live PDF Preview
        Expanded(
          flex: 9,
          child: Container(
            color: kMuted.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: kCard,
                    border: Border(
                      bottom: BorderSide(color: kBorder, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: kPrimary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Live Invoice Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(primaryColor: kPrimary),
                    child: PdfPreview(
                      build: (format) => InvoicePdfService.buildPdf(invoice),
                      useActions: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      loadingWidget: const Center(
                        child: CircularProgressIndicator(),
                      ),
                      pdfPreviewPageDecoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile Mode Layout ─────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, InvoiceDraft draft) {
    return Column(
      children: [
        _Header(onHistory: () => context.push('/InvoiceHistory')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: [
              _DateCard(
                date: draft.invoiceDate,
                onChanged: ref.read(invoiceDraftProvider.notifier).setDate,
              ),
              const SizedBox(height: 20),
              _sectionLabel(
                AppLocalizations.of(context)!.billingCustomerSection +
                    " & " +
                    AppLocalizations.of(context)!.billingVehicleSection,
              ),
              const SizedBox(height: 10),
              BillingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BillingCustomerSection(),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: kBorder)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 14,
                                color: kMutedForeground,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Vehicle',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kMutedForeground,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Divider(color: kBorder)),
                      ],
                    ),
                    SizedBox(height: 14),
                    BillingVehicleSection(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const BillingItemsSection(),
              const SizedBox(height: 20),
              const LabourCard(), // ← ye naya add karo
              const SizedBox(height: 20),
              if (draft.items.isNotEmpty) ...[
                const BillingSummarySection(),
                const SizedBox(height: 20),
              ],
              _PaymentCard(
                draft: draft,
                onStatus: ref
                    .read(invoiceDraftProvider.notifier)
                    .setPaymentStatus,
                onMethod: ref
                    .read(invoiceDraftProvider.notifier)
                    .setPaymentMethod,
              ),
              const SizedBox(height: 20),
              _NotesCard(ctrl: _notesCtrl),
            ],
          ),
        ),
        _SaveBar(isSaving: _isSaving, onSave: _saveInvoice, onClear: _clearAll),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: kMutedForeground,
      letterSpacing: 0.3,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Remaining sub-widgets (specific layout pieces of the main Billing screen)
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onHistory;
  const _Header({required this.onHistory});

  @override
  Widget build(BuildContext context) => Container(
    color: kCard,
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 6,
      left: 4,
      right: 12,
      bottom: 12,
    ),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: kForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.billingTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: kForeground,
              letterSpacing: -0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: onHistory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 15, color: kMutedForeground),
                const SizedBox(width: 5),
                Text(
                  AppLocalizations.of(context)!.billingHistory,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kMutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
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
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (p != null) onChanged(p);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.billingInvoiceDate,
                style: TextStyle(
                  fontSize: 11,
                  color: kMutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd MMMM yyyy').format(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kForeground,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.edit_calendar_rounded, size: 16, color: kMutedForeground),
        ],
      ),
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  final InvoiceDraft draft;
  final ValueChanged<PaymentStatus> onStatus;
  final ValueChanged<PaymentMethod> onMethod;
  const _PaymentCard({
    required this.draft,
    required this.onStatus,
    required this.onMethod,
  });

  @override
  Widget build(BuildContext context) => BillingCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.billingPayment,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: kForeground,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.of(context)!.billingStatus,
          style: TextStyle(
            fontSize: 11,
            color: kMutedForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
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
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.12) : kMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _localStatus(context, s),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? color : kMutedForeground,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.of(context)!.billingMethod,
          style: TextStyle(
            fontSize: 11,
            color: kMutedForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PaymentMethod.values.map((m) {
            final sel = draft.paymentMethod == m;
            return GestureDetector(
              onTap: () => onMethod(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFE8F0FE) : kMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? kPrimary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _localMethod(context, m),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? kPrimary : kMutedForeground,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  String _localStatus(BuildContext context, PaymentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case PaymentStatus.paid:
        return l10n.statusPaid;
      case PaymentStatus.pending:
        return l10n.statusPending;
      case PaymentStatus.partial:
        return l10n.statusPartial;
    }
  }

  String _localMethod(BuildContext context, PaymentMethod method) {
    final l10n = AppLocalizations.of(context)!;
    switch (method) {
      case PaymentMethod.cash:
        return l10n.methodCash;
      case PaymentMethod.upi:
        return l10n.methodUpi;
      case PaymentMethod.card:
        return l10n.methodCard;
      case PaymentMethod.bank:
        return l10n.methodBank;
      case PaymentMethod.pending:
        return l10n.methodPending;
    }
  }
}

class _NotesCard extends StatelessWidget {
  final TextEditingController ctrl;
  const _NotesCard({required this.ctrl});

  @override
  Widget build(BuildContext context) => BillingCard(
    child: TextField(
      controller: ctrl,
      maxLines: 3,
      style: TextStyle(fontSize: 13, color: kForeground),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.billingNotesHint,
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

class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave, onClear;
  const _SaveBar({
    required this.isSaving,
    required this.onSave,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    child: Row(
      children: [
        GestureDetector(
          onTap: onClear,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: kMutedForeground,
              size: 20,
            ),
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
                  colors: [Color(0xFFFDB913), Color(0xFFFDB918)],
                ),
                color: isSaving ? kMuted : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSaving
                    ? []
                    : [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimary,
                  ),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.save_alt_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.billingButtonSave,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}