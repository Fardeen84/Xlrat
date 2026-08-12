// lib/screen/navigation_screen/Billing/InvoiceHistoryScreen.dart

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/billing_model/invoice.dart';
import '../../../providers/billing_providers.dart';
import '../../../core/Theme.dart';

// ─── Local state providers (scoped to this screen) ───────────────────────────

/// Search query local to the history screen.
final _historySearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Status filter local to the history screen.
final _historyStatusFilterProvider = StateProvider.autoDispose<PaymentStatus?>(
      (ref) => null,
);

// ─────────────────────────────────────────────────────────────────────────────
// InvoiceHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceHistoryScreen extends ConsumerStatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  ConsumerState<InvoiceHistoryScreen> createState() =>
      _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends ConsumerState<InvoiceHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showExportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Export Data',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kForeground,
          ),
        ),
        content: Text(
          'Choose the format in which you want to export your invoices.',
          style: TextStyle(fontSize: 14, color: kMutedForeground),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _exportData(context, isCsv: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Export CSV (Excel compatible)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _exportData(context, isCsv: false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimary, width: 1.2),
                    foregroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Export JSON (App backup)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: kMutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, {required bool isCsv}) async {
    try {
      final repo = ref.read(billingRepositoryProvider);
      final allInvoices = await repo.getInvoices();

      if (allInvoices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No invoices found to export.'),
              backgroundColor: kOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Could not access Downloads directory.');
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String fileName;
      final String fileContent;

      if (isCsv) {
        fileName = 'xlrat_bills_export.csv';
        final List<List<dynamic>> rows = [];
        rows.add([
          'Invoice Number',
          'Invoice Date',
          'Customer Name',
          'Customer Mobile',
          'Customer Email',
          'Vehicle Number',
          'Vehicle Model',
          'Item Name',
          'Quantity',
          'Unit',
          'Price',
          'Item Total',
          'Subtotal',
          'Discount',
          'GST',
          'Grand Total',
          'Payment Status',
          'Payment Method',
          'Notes',
        ]);

        for (final inv in allInvoices) {
          final invDateStr = DateFormat('yyyy-MM-dd').format(inv.invoiceDate);
          if (inv.items.isEmpty) {
            rows.add([
              inv.invoiceNumber,
              invDateStr,
              inv.customer?.name ?? '',
              inv.customer?.mobile ?? '',
              inv.customer?.email ?? '',
              inv.vehicle?.vehicleNumber ?? '',
              inv.vehicle?.vehicleModel ?? '',
              '',
              0.0,
              '',
              0.0,
              0.0,
              inv.subTotal,
              inv.discount,
              inv.gst,
              inv.grandTotal,
              inv.paymentStatus.label,
              inv.paymentMethod.label,
              inv.notes,
            ]);
          } else {
            for (final item in inv.items) {
              rows.add([
                inv.invoiceNumber,
                invDateStr,
                inv.customer?.name ?? '',
                inv.customer?.mobile ?? '',
                inv.customer?.email ?? '',
                inv.vehicle?.vehicleNumber ?? '',
                inv.vehicle?.vehicleModel ?? '',
                item.itemName,
                item.quantity,
                item.unit,
                item.price,
                item.total,
                inv.subTotal,
                inv.discount,
                inv.gst,
                inv.grandTotal,
                inv.paymentStatus.label,
                inv.paymentMethod.label,
                inv.notes,
              ]);
            }
          }
        }
        fileContent = const ListToCsvConverter().convert(rows);
      } else {
        fileName = 'xlrat_backup_$dateStr.json';
        final List<Map<String, dynamic>> jsonData = [];
        for (final inv in allInvoices) {
          final invDateStr = DateFormat('yyyy-MM-dd').format(inv.invoiceDate);
          if (inv.items.isEmpty) {
            jsonData.add({
              'Invoice Number': inv.invoiceNumber,
              'Invoice Date': invDateStr,
              'Customer Name': inv.customer?.name ?? '',
              'Customer Mobile': inv.customer?.mobile ?? '',
              'Customer Email': inv.customer?.email ?? '',
              'Vehicle Number': inv.vehicle?.vehicleNumber ?? '',
              'Vehicle Model': inv.vehicle?.vehicleModel ?? '',
              'Item Name': '',
              'Quantity': 0.0,
              'Unit': '',
              'Price': 0.0,
              'Item Total': 0.0,
              'Subtotal': inv.subTotal,
              'Discount': inv.discount,
              'GST': inv.gst,
              'Grand Total': inv.grandTotal,
              'Payment Status': inv.paymentStatus.label,
              'Payment Method': inv.paymentMethod.label,
              'Notes': inv.notes,
            });
          } else {
            for (final item in inv.items) {
              jsonData.add({
                'Invoice Number': inv.invoiceNumber,
                'Invoice Date': invDateStr,
                'Customer Name': inv.customer?.name ?? '',
                'Customer Mobile': inv.customer?.mobile ?? '',
                'Customer Email': inv.customer?.email ?? '',
                'Vehicle Number': inv.vehicle?.vehicleNumber ?? '',
                'Vehicle Model': inv.vehicle?.vehicleModel ?? '',
                'Item Name': item.itemName,
                'Quantity': item.quantity,
                'Unit': item.unit,
                'Price': item.price,
                'Item Total': item.total,
                'Subtotal': inv.subTotal,
                'Discount': inv.discount,
                'GST': inv.gst,
                'Grand Total': inv.grandTotal,
                'Payment Status': inv.paymentStatus.label,
                'Payment Method': inv.paymentMethod.label,
                'Notes': inv.notes,
              });
            }
          }
        }
        fileContent = const JsonEncoder.withIndent('  ').convert(jsonData);
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(fileContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to Downloads/$fileName'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteInvoice(BuildContext context, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Invoice',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kForeground,
          ),
        ),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNumber}? '
              'This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: kMutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: kMutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: kRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(billingRepositoryProvider);
      await repo.deleteInvoice(invoice.id!);
      ref.invalidate(invoicesListStateProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${invoice.invoiceNumber} deleted'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(_historySearchProvider);
    final statusFilter = ref.watch(_historyStatusFilterProvider);

    // Drive invoiceListProvider with local state by syncing providers
    ref.listen<String>(_historySearchProvider, (_, q) {
      ref.read(invoiceSearchQueryProvider.notifier).state = q;
    });
    ref.listen<PaymentStatus?>(_historyStatusFilterProvider, (_, s) {
      ref.read(invoiceStatusFilterProvider.notifier).state = s;
    });

    final invoicesAsync = ref.watch(invoiceListProvider);

    return Scaffold(
      backgroundColor: kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/billing'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Create Invoice',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(invoicesListStateProvider),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: kCard,
              elevation: 0,
              scrolledUnderElevation: 1,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: kForeground),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
              title: Text(
                'Invoice History',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kForeground,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    color: kPrimary,
                  ),
                  tooltip: 'Export Data',
                  onPressed: () => _showExportDialog(context),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(112),
                child: Container(
                  color: kCard,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search bar
                      _HistorySearchBar(
                        controller: _searchCtrl,
                        value: searchQuery,
                        onChanged: (q) {
                          ref.read(_historySearchProvider.notifier).state = q;
                        },
                        onClear: () {
                          _searchCtrl.clear();
                          ref.read(_historySearchProvider.notifier).state = '';
                        },
                      ),
                      const SizedBox(height: 10),
                      // Status Filter Chips
                      _StatusFilterRow(
                        selected: statusFilter,
                        onChanged: (s) =>
                        ref
                            .read(_historyStatusFilterProvider.notifier)
                            .state =
                            s,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Invoice List ─────────────────────────────────────────────────
            invoicesAsync.when(
              loading: () => const SliverFillRemaining(child: _LoadingState()),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorState(
                  error: e.toString(),
                  onRetry: () => ref.invalidate(invoicesListStateProvider),
                ),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(
                      isFiltered:
                      searchQuery.isNotEmpty || statusFilter != null,
                      onCreateInvoice: () => context.push('/billing'),
                    ),
                  );
                }

                final hasMore = ref.watch(invoicesListStateProvider).hasMore;
                final isLoadMore = ref.watch(invoicesListStateProvider).isLoadMore;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList.builder(
                    itemCount: invoices.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == invoices.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: isLoadMore
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                              onPressed: () => ref.read(invoicesListStateProvider.notifier).loadMore(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Load More'),
                            ),
                          ),
                        );
                      }
                      final invoice = invoices[index];
                      return _InvoiceCard(
                        invoice: invoice,
                        onTap: () => context.push('/invoice/${invoice.id}'),
                        onView: () => context.push('/invoice/${invoice.id}'),
                        onEdit: () async {
                          final freshInvoice = await ref
                              .read(billingRepositoryProvider)
                              .getInvoice(invoice.id!);
                          if (freshInvoice == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invoice not found'),
                                ),
                              );
                            }
                            return;
                          }
                          ref
                              .read(invoiceDraftProvider.notifier)
                              .loadForEdit(freshInvoice);
                          if (context.mounted) context.push('/billing');
                        },
                        onDelete: () => _deleteInvoice(context, invoice),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar Widget
// ─────────────────────────────────────────────────────────────────────────────

class _HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _HistorySearchBar({
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: kMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(
              Icons.search_rounded,
              color: kMutedForeground,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: kForeground),
              decoration: InputDecoration(
                hintText: 'Search invoice, customer, vehicle…',
                hintStyle: TextStyle(color: kMutedForeground, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                isDense: true,
                suffixIcon: value.isNotEmpty
                    ? GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    color: kMutedForeground,
                    size: 16,
                  ),
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Filter Chips Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  final PaymentStatus? selected;
  final ValueChanged<PaymentStatus?> onChanged;

  const _StatusFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusChipItem(
            label: 'All',
            isSelected: selected == null,
            color: kPrimary,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _StatusChipItem(
            label: 'Paid',
            isSelected: selected == PaymentStatus.paid,
            color: kGreen,
            onTap: () => onChanged(PaymentStatus.paid),
          ),
          const SizedBox(width: 8),
          _StatusChipItem(
            label: 'Pending',
            isSelected: selected == PaymentStatus.pending,
            color: kOrange,
            onTap: () => onChanged(PaymentStatus.pending),
          ),
          const SizedBox(width: 8),
          _StatusChipItem(
            label: 'Partial',
            isSelected: selected == PaymentStatus.partial,
            color: kAccent,
            onTap: () => onChanged(PaymentStatus.partial),
          ),
        ],
      ),
    );
  }
}

class _StatusChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChipItem({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : kMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? color : kMutedForeground,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onView;
  final Future<void> Function() onEdit;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      final Uri url = Uri(scheme: 'tel', path: phoneNumber);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      } catch (e) {
        print('Could not launch call url: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(invoice.id),
        background: _SwipeBackground(
          alignment: Alignment.centerLeft,
          color: kGreen,
          icon: Icons.visibility_rounded,
          label: 'View',
        ),
        secondaryBackground: _SwipeBackground(
          alignment: Alignment.centerRight,
          color: kRed,
          icon: Icons.delete_rounded,
          label: 'Delete',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onView();
            return false;
          } else {
            onDelete();
            return false;
          }
        },
        child: Material(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Card Top Row ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
                    child: Row(
                      children: [
                        // Avatar
                        _CustomerAvatar(
                          name: invoice.customer?.name ?? 'Unknown',
                        ),
                        const SizedBox(width: 12),

                        // Customer + Invoice info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.customer?.name ?? 'Unknown Customer',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kForeground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                invoice.invoiceNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kMutedForeground,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status badge + Menu & Call
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _PaymentStatusBadge(status: invoice.paymentStatus),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (invoice.customer?.mobile != null &&
                                    invoice.customer!.mobile.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.phone_rounded,
                                      color: kGreen,
                                      size: 18,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _makeCall(invoice.customer!.mobile),
                                  ),
                                const SizedBox(width: 8),
                                _CardPopupMenu(
                                  onView: onView,
                                  onEdit: onEdit,
                                  onDelete: onDelete,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Divider ───────────────────────────────────────────────
                  Divider(height: 1, color: kBorder, indent: 14, endIndent: 14),

                  // ── Card Details Row ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Row(
                      children: [
                        // Vehicle info
                        Expanded(
                          flex: 3,
                          child: _InfoTile(
                            icon: Icons.directions_car_rounded,
                            label: 'Vehicle',
                            value: invoice.vehicle != null
                                ? invoice.vehicle!.vehicleNumber
                                : '—',
                          ),
                        ),

                        // Model
                        if (invoice.vehicle != null &&
                            invoice.vehicle!.vehicleModel.isNotEmpty)
                          Expanded(
                            flex: 3,
                            child: _InfoTile(
                              icon: Icons.branding_watermark_rounded,
                              label: 'Model',
                              value: invoice.vehicle!.vehicleModel,
                            ),
                          ),

                        // Date
                        Expanded(
                          flex: 3,
                          child: _InfoTile(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: DateFormat(
                              'dd MMM yy',
                            ).format(invoice.invoiceDate),
                          ),
                        ),

                        // Amount
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kMutedForeground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${_formatAmount(invoice.grandTotal)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: kPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      final s = amount.round().toString();
      return s.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+\d$)'),
            (m) => '${m[1]},',
      );
    }
    return amount.round().toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Popup Menu
// ─────────────────────────────────────────────────────────────────────────────

class _CardPopupMenu extends StatelessWidget {
  final VoidCallback onView;
  final Future<void> Function() onEdit;
  final VoidCallback onDelete;

  const _CardPopupMenu({
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: kMutedForeground, size: 18),
      padding: EdgeInsets.zero,
      iconSize: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: kCard,
      elevation: 4,
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_rounded, size: 16, color: kPrimary),
              SizedBox(width: 10),
              Text(
                'View',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kForeground,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 16, color: kOrange),
              SizedBox(width: 10),
              Text(
                'Edit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kForeground,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 16, color: kRed),
              SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kRed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe Background
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Status Badge
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const _PaymentStatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case PaymentStatus.paid:
        return kGreen;
      case PaymentStatus.pending:
        return kOrange;
      case PaymentStatus.partial:
        return kAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerAvatar extends StatelessWidget {
  final String name;

  const _CustomerAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: kPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Tile
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: kMutedForeground),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: kMutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: kForeground,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onCreateInvoice;

  const _EmptyState({required this.isFiltered, required this.onCreateInvoice});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kMuted,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_rounded,
                size: 36,
                color: kMutedForeground,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No results found' : 'No invoices found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: kForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try adjusting your search or filter'
                  : 'Create your first invoice to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kMutedForeground),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: onCreateInvoice,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFDB913), Color(0xFFFDB918)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Create Invoice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading State
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 6,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final gradient = LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value + 1, 0),
          colors: const [
            Color(0xFFEEF1F6),
            Color(0xFFE2E6ED),
            Color(0xFFEEF1F6),
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: kRed,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: kForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: kMutedForeground),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}