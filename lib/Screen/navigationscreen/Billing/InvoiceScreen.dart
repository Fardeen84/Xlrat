
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../Models/Billing model/InvoiceItem.dart';
import '../../../Models/Billing model/invoice.dart';
import '../../../Providers/billing_providers.dart';
import '../../../core/Theme.dart';

class InvoiceScreen extends ConsumerWidget {
final int invoiceId;
const InvoiceScreen({super.key, required this.invoiceId});

@override
Widget build(BuildContext context, WidgetRef ref) {
final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));

return Scaffold(
backgroundColor: kBackground,
body: invoiceAsync.when(
loading: () => const Center(child: CircularProgressIndicator()),
error: (e, _) => Center(child: Text('Error loading invoice: $e')),
data: (invoice) {
if (invoice == null) {
return const Center(child: Text('Invoice not found'));
}
return _InvoiceBody(invoice: invoice);
},
),
);
}
}

class _InvoiceBody extends StatelessWidget {
final Invoice invoice;
const _InvoiceBody({required this.invoice});

@override
Widget build(BuildContext context) {
final customer = invoice.customer;
final vehicle = invoice.vehicle;

return Column(
children: [
// ── Top Bar ─────────────────────────────────────────────────────
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
onPressed: () => context.go('/invoice-history'),
),
const Expanded(
child: Text('Invoice',
style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kForeground)),
),
_StatusChip(status: invoice.paymentStatus),
],
),
),

// ── Invoice Document ─────────────────────────────────────────────
Expanded(
child: SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Container(
decoration: BoxDecoration(
color: kCard,
borderRadius: BorderRadius.circular(24),
border: Border.all(color: kBorder.withOpacity(0.5)),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)],
),
clipBehavior: Clip.hardEdge,
child: Column(
children: [
// ── Gradient Header ──────────────────────────────────
Container(
padding: const EdgeInsets.all(24),
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
),
),
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Row(
children: [
Icon(Icons.build_rounded, color: Colors.white, size: 16),
SizedBox(width: 6),
Text('Fradeen Auto Garage',
style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
],
),
const SizedBox(height: 4),
Text('GST: 27AABCV1234A1ZB',
style: TextStyle(color: Colors.blue[200], fontSize: 11)),
Text('+91 98765 43210',
style: TextStyle(color: Colors.blue[200], fontSize: 11)),
],
),
),
Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
const Text('TAX',
style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
Text('INVOICE', style: TextStyle(color: Colors.blue[200], fontSize: 13)),
],
),
],
),
),

Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
// ── Bill To + Invoice No ──────────────────────
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('BILL TO',
style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
color: kMutedForeground, letterSpacing: 0.8)),
const SizedBox(height: 6),
Text(customer?.name ?? '—',
style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
if (customer?.mobile.isNotEmpty == true)
Text('+91 ${customer!.mobile}',
style: const TextStyle(fontSize: 12, color: kMutedForeground)),
if (customer?.email.isNotEmpty == true)
Text(customer!.email,
style: const TextStyle(fontSize: 12, color: kMutedForeground)),
if (vehicle != null) ...[
const SizedBox(height: 4),
Text(vehicle.displayLabel,
style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kPrimary)),
],
],
),
),
Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
const Text('INVOICE NO.',
style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
color: kMutedForeground, letterSpacing: 0.8)),
const SizedBox(height: 6),
Text(invoice.invoiceNumber,
style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kForeground)),
Text(DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
style: const TextStyle(fontSize: 11, color: kMutedForeground)),
const SizedBox(height: 4),
Text(invoice.paymentStatus.label.toUpperCase(),
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w800,
color: _statusColor(invoice.paymentStatus),
)),
],
),
],
),

const SizedBox(height: 20),
const Divider(color: kBorder),
const SizedBox(height: 12),

// ── Table Header ──────────────────────────────
const Row(
children: [
Expanded(flex: 6, child: Text('ITEM',
style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
SizedBox(width: 44, child: Text('QTY', textAlign: TextAlign.center,
style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
Expanded(flex: 2, child: Text('RATE', textAlign: TextAlign.right,
style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
Expanded(flex: 2, child: Text('AMT', textAlign: TextAlign.right,
style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.6))),
],
),
const SizedBox(height: 8),

// ── Line Items from DB ────────────────────────
...invoice.items.map((item) => _LineItemRow(item: item)),

const Divider(color: kBorder),
const SizedBox(height: 12),

// ── Totals ────────────────────────────────────
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: kMuted,
borderRadius: BorderRadius.circular(16),
),
child: Column(
children: [
_TotalRow('Subtotal', formatCurrency(invoice.subTotal.round())),
if (invoice.gst > 0)
_TotalRow('GST', formatCurrency(invoice.gst.round())),
if (invoice.discount > 0)
_TotalRow('Discount', '- ${formatCurrency(invoice.discount.round())}'),
const Divider(color: kBorder),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text('Grand Total',
style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
Text(formatCurrency(invoice.grandTotal.round()),
style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary)),
],
),
],
),
),

// ── Payment method ────────────────────────────
if (invoice.paymentMethod != PaymentMethod.pending) ...[
const SizedBox(height: 12),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.payment_rounded, size: 14, color: kMutedForeground),
const SizedBox(width: 4),
Text('Payment via ${invoice.paymentMethod.label}',
style: const TextStyle(fontSize: 12, color: kMutedForeground)),
],
),
],

if (invoice.notes.isNotEmpty) ...[
const SizedBox(height: 12),
Container(
width: double.infinity,
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: const Color(0xFFFFF8E1),
borderRadius: BorderRadius.circular(12),
),
child: Text(invoice.notes,
style: const TextStyle(fontSize: 12, color: kForeground)),
),
],

const SizedBox(height: 20),
const Text('Thank you for choosing Fradeen Auto Garage!',
textAlign: TextAlign.center,
style: TextStyle(fontSize: 12, color: kMutedForeground)),
const SizedBox(height: 8),
],
),
),
],
),
),
),
),

// ── Bottom Actions ───────────────────────────────────────────────
Container(
color: kCard,
padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
child: Row(
children: [
Expanded(
child: ElevatedButton.icon(
onPressed: () {},
icon: const Icon(Icons.download_rounded, size: 16),
label: const Text('Download PDF'),
style: ElevatedButton.styleFrom(
backgroundColor: kPrimary,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 14),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
),
),
),
const SizedBox(width: 10),
Expanded(
child: OutlinedButton.icon(
onPressed: () {},
icon: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF15803D)),
label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF15803D))),
style: OutlinedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 14),
side: const BorderSide(color: Color(0xFF15803D)),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
),
),
),
],
),
),
],
);
}

Color _statusColor(PaymentStatus s) {
switch (s) {
case PaymentStatus.paid: return const Color(0xFF15803D);
case PaymentStatus.partial: return kOrange;
case PaymentStatus.pending: return kRed;
}
}
}

class _LineItemRow extends StatelessWidget {
final InvoiceItem item;
const _LineItemRow({required this.item});

@override
Widget build(BuildContext context) => Padding(
padding: const EdgeInsets.symmetric(vertical: 8),
child: Row(
children: [
Expanded(flex: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(item.itemName, style: const TextStyle(fontSize: 12, color: kForeground, fontWeight: FontWeight.w500)),
Text(item.unit, style: const TextStyle(fontSize: 10, color: kMutedForeground)),
])),
SizedBox(width: 44, child: Text(
item.quantity % 1 == 0 ? '${item.quantity.toInt()}' : item.quantity.toStringAsFixed(1),
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 12, color: kMutedForeground),
)),
Expanded(flex: 2, child: Text('₹${item.price.toInt()}', textAlign: TextAlign.right,
style: const TextStyle(fontSize: 12, color: kMutedForeground))),
Expanded(flex: 2, child: Text('₹${item.total.toInt()}', textAlign: TextAlign.right,
style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kForeground))),
],
),
);
}

class _TotalRow extends StatelessWidget {
final String label;
final String value;
const _TotalRow(this.label, this.value);

@override
Widget build(BuildContext context) => Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
Text(label, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kForeground)),
]),
);
}

class _StatusChip extends StatelessWidget {
final PaymentStatus status;
const _StatusChip({required this.status});

@override
Widget build(BuildContext context) {
final Color color;
final Color bg;
switch (status) {
case PaymentStatus.paid:
color = const Color(0xFF15803D); bg = const Color(0xFFECFDF5); break;
case PaymentStatus.partial:
color = kOrange; bg = const Color(0xFFFFF3E0); break;
case PaymentStatus.pending:
color = kRed; bg = const Color(0xFFFEF2F2); break;
}
return Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
child: Text(status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
);
}
}