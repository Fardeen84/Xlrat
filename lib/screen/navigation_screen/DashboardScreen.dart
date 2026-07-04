// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../models/billing_model/invoice.dart';
import '../../models/InventoryItem.dart';
import '../../providers/NavigationProvider.dart';
import '../../providers/billing_providers.dart';
import '../../providers/inventoryProvider.dart';
import '../../models/job.dart';
import '../../providers/jobsProvider.dart';
import '../../providers/notificationsProvider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/billing_providers.dart';
import '../../providers/firestoreServiceProvider.dart';

import '../../core/Theme.dart';
import '../../widgets/StatusBadge.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      try {
        ref.read(cloudSyncServiceProvider).pullRemoteInvoices();
      } catch (e) {
        print('Failed to trigger pullRemoteInvoices: $e');
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);
    final lowStockAsync = ref.watch(lowStockItemsProvider);
    final lowStock = lowStockAsync.value ?? [];
    final invoicesAsync = ref.watch(invoiceListProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final jobs = jobsAsync.value ?? [];
    final todaySummaryAsync = ref.watch(todaySummaryProvider);
    final customersAsync = ref.watch(customerListProvider);
    final totalCustomers = customersAsync.value?.length ?? 0;
    final profileState = ref.watch(profileProvider);
    final displayName = profileState.garageName.isNotEmpty ? profileState.garageName : 'My Garage';

    final searchQuery = ref.watch(dashboardSearchQueryProvider);
    final searchResultsAsync = ref.watch(dashboardSearchResultsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPC = constraints.maxWidth > 1100;
          if (isPC) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPCLayout(
                      context,
                      ref,
                      unreadCount,
                      lowStock,
                      invoicesAsync,
                      jobs,
                      todaySummaryAsync,
                      totalCustomers,
                    ),
                  ],
                ),
              ),
            );
          } else {
            return _buildMobileLayout(
              context,
              ref,
              unreadCount,
              lowStock,
              invoicesAsync,
              jobs,
              todaySummaryAsync,
              totalCustomers,
              displayName,
              searchQuery,
              searchResultsAsync,
            );
          }
        },
      ),
    );
  }

  // ── PC Layout ──────────────────────────────────────────────────────────────
  Widget _buildPCLayout(
    BuildContext context,
    WidgetRef ref,
    int unreadCount,
    List<InventoryItem> lowStock,
    AsyncValue<List<Invoice>> invoicesAsync,
    List<Job> jobs,
    AsyncValue<({double total, int count})> todaySummaryAsync,
    int totalCustomers,
  ) {
    final activeJobs = jobs.where((j) => j.status != 'completed').toList();
    final todaySalesStr = todaySummaryAsync.maybeWhen(
      data: (summary) => formatCurrency(summary.total.round()),
      orElse: () => '₹0',
    );
    final todaySalesSub = todaySummaryAsync.maybeWhen(
      data: (summary) => AppLocalizations.of(context)!.dashboardStatBillsGenerated(summary.count),
      orElse: () => AppLocalizations.of(context)!.dashboardStatBillsGenerated(0),
    );
    final pendingCount = jobs.where((j) => j.status == 'pending').length;
    final inProgressCount = jobs.where((j) => j.status == 'in-progress').length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Area (2/3 width) ──
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Grid (1 row of 4 cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        _StatCard(
                          label: AppLocalizations.of(context)!.dashboardStatTodaysSales,
                          value: todaySalesStr,
                          sub: todaySalesSub,
                          icon: Icons.currency_rupee_rounded,
                          color: Colors.blue,
                          iconBg: const Color(0xFFE3F2FD),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        _StatCard(
                          label: AppLocalizations.of(context)!.dashboardStatPendingJobs,
                          value: '$pendingCount',
                          sub: AppLocalizations.of(context)!.dashboardStatInProgressCount(inProgressCount),
                          icon: Icons.access_time_rounded,
                          color: Colors.orange,
                          iconBg: const Color(0xFFFFF3E0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        _StatCard(
                          label: AppLocalizations.of(context)!.dashboardStatCompletedJobs,
                          value:
                              '${jobs.where((j) => j.status == 'completed').length}',
                          sub: AppLocalizations.of(context)!.dashboardStatCompletedToday,
                          icon: Icons.check_circle_rounded,
                          color: Colors.green,
                          iconBg: const Color(0xFFE8F5E9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        _StatCard(
                          label: AppLocalizations.of(context)!.dashboardStatTotalCustomers,
                          value: '$totalCustomers',
                          sub: AppLocalizations.of(context)!.dashboardStatRegistered,
                          icon: Icons.people_rounded,
                          color: Colors.blue,
                          iconBg: const Color(0xFFE3F2FD),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Active Jobs Table
                Container(
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          AppLocalizations.of(context)!.dashboardSectionActiveJobs,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: kForeground,
                          ),
                        ),
                      ),
                      if (activeJobs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(child: Text(AppLocalizations.of(context)!.dashboardNoActiveJobs)),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Customer')),
                              DataColumn(label: Text('Vehicle')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Action')),
                            ],
                            rows: activeJobs.take(5).map((job) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      job.customer,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text('${job.vehicle} (${job.brand})'),
                                  ),
                                  DataCell(StatusBadge(status: job.status)),
                                  DataCell(Text(formatCurrency(job.amount))),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: kPrimary,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        ref
                                                .read(
                                                  selectedJobProvider.notifier,
                                                )
                                                .state =
                                            job;
                                        context.push('/job-detail/${job.id}');
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Activity (Recent Invoices)
                Container(
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Invoices / Bills',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: kForeground,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/InvoiceHistory'),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                      invoicesAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (e, _) => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Could not load invoices'),
                          ),
                        ),
                        data: (invoices) {
                          if (invoices.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('No invoices yet')),
                            );
                          }
                          return Column(
                            children: invoices.take(4).map((inv) {
                              return _BillCard(
                                invoice: inv,
                                onTap: () => context.push('/invoice/${inv.id}'),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // ── Side Area (1/3 width) ──
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Billing Summary Card
                todaySummaryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const SizedBox(),
                  data: (summary) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Summary",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatCurrency(summary.total.round()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${summary.count} invoices generated today",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kForeground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPCQuickActionRow(
                        'Add customer',
                        Icons.person_add_rounded,
                        const Color(0xFFE3F2FD),
                        Colors.blue,
                        () => context.go('/customers'),
                      ),
                      const SizedBox(height: 12),
                      _buildPCQuickActionRow(
                        'New job card',
                        Icons.add_task_rounded,
                        const Color(0xFFE8F5E9),
                        Colors.green,
                        () => context.push('/new-job'),
                      ),
                      const SizedBox(height: 12),
                      _buildPCQuickActionRow(
                        'Create invoice',
                        Icons.receipt_long_rounded,
                        const Color(0xFFFFF3E0),
                        Colors.orange,
                        () => context.push('/billing'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Low Stock Warnings List
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.dashboardSectionLowStockAlert,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kForeground,
                            ),
                          ),
                          if (lowStock.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${lowStock.length}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (lowStock.isEmpty)
                        Text(
                          AppLocalizations.of(context)!.dashboardNoLowStock,
                          style: const TextStyle(
                            color: kMutedForeground,
                            fontSize: 12,
                          ),
                        )
                      else
                        Column(
                          children: List.generate(lowStock.take(5).length, (
                            idx,
                          ) {
                            final item = lowStock[idx];
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: kForeground,
                                            ),
                                          ),
                                          Text(
                                            'Stock: ${item.stock} ${item.unit} (Min: ${item.minStock})',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: kMutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/inventory'),
                                      child: const Text(
                                        'Restock',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                if (idx < lowStock.take(5).length - 1)
                                  const Divider(color: kBorder, height: 16),
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPCQuickActionRow(
    String label,
    IconData icon,
    Color iconBg,
    MaterialColor iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder, width: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor.shade700),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kForeground,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: kMutedForeground,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    int unreadCount,
    List<InventoryItem> lowStock,
    AsyncValue<List<Invoice>> invoicesAsync,
    List<Job> jobs,
    AsyncValue<({double total, int count})> todaySummaryAsync,
    int totalCustomers,
    String garageName,
    String searchQuery,
    AsyncValue<List<Invoice>> searchResultsAsync,
  ) {
    final todaySalesStr = todaySummaryAsync.maybeWhen(
      data: (summary) => formatCurrency(summary.total.round()),
      orElse: () => '₹0',
    );
    final todaySalesSub = todaySummaryAsync.maybeWhen(
      data: (summary) => AppLocalizations.of(context)!.dashboardStatBillsGenerated(summary.count),
      orElse: () => AppLocalizations.of(context)!.dashboardStatBillsGenerated(0),
    );
    final pendingCount = jobs.where((j) => j.status == 'pending').length;
    final inProgressCount = jobs.where((j) => j.status == 'in-progress').length;

    final statCards = [
      _StatCard(
        label: AppLocalizations.of(context)!.dashboardStatTodaysSales,
        value: todaySalesStr,
        sub: todaySalesSub,
        icon: Icons.currency_rupee_rounded,
        color: Colors.blue,
        iconBg: const Color(0xFFE3F2FD),
      ),
      _StatCard(
        label: AppLocalizations.of(context)!.dashboardStatPendingJobs,
        value: '$pendingCount',
        sub: AppLocalizations.of(context)!.dashboardStatInProgressCount(inProgressCount),
        icon: Icons.access_time_rounded,
        color: Colors.orange,
        iconBg: const Color(0xFFFFF3E0),
      ),
      _StatCard(
        label: AppLocalizations.of(context)!.dashboardStatCompleted,
        value: '${jobs.where((j) => j.status == 'completed').length}',
        sub: AppLocalizations.of(context)!.dashboardStatCompletedToday,
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        iconBg: const Color(0xFFE8F5E9),
      ),
      _StatCard(
        label: AppLocalizations.of(context)!.dashboardStatTotalCustomers,
        value: '$totalCustomers',
        sub: AppLocalizations.of(context)!.dashboardStatRegistered,
        icon: Icons.people_rounded,
        color: Colors.blue,
        iconBg: const Color(0xFFE3F2FD),
      ),
    ];

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(
                            color: Colors.blue[200],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          garageName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: kOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(
                          Icons.search_rounded,
                          color: kMutedForeground,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) {
                            setState(() {});
                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                            _debounce = Timer(const Duration(milliseconds: 300), () {
                              ref.read(dashboardSearchQueryProvider.notifier).state = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.dashboardSearchHint,
                            hintStyle: const TextStyle(
                              color: kMutedForeground,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: kMutedForeground),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      ref.read(dashboardSearchQueryProvider.notifier).state = '';
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: searchResultsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error: $err', style: const TextStyle(color: kRed)),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No matching invoices found',
                                style: TextStyle(color: kMutedForeground, fontSize: 13),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
                          itemBuilder: (context, index) {
                            final invoice = results[index];
                            return ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: kMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: kPrimary, size: 18),
                              ),
                              title: Text(
                                invoice.invoiceNumber,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kForeground),
                              ),
                              subtitle: Text(
                                '${invoice.customer?.name ?? 'Unknown Customer'} • ${invoice.vehicle?.vehicleNumber ?? 'No Vehicle'}',
                                style: const TextStyle(fontSize: 11, color: kMutedForeground),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatCurrency(invoice.grandTotal.round()),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kForeground),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        invoice.paymentStatus.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: invoice.paymentStatus == PaymentStatus.paid ? kGreen : kOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.person_outline_rounded, color: kMutedForeground, size: 20),
                                    onPressed: () {
                                      context.push('/customer-detail/${invoice.customerId}');
                                    },
                                    tooltip: 'View Customer',
                                  ),
                                ],
                              ),
                              onTap: () {
                                context.push('/invoice/${invoice.id}');
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Body
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Stat Cards
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(statCards[0])),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard(statCards[1])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(statCards[2])),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatCard(statCards[3])),
                    ],
                  ),
                ],
              ),

              // Low Stock Alert
              if (lowStock.isNotEmpty) ...[
                const SizedBox(height: 14),
                _LowStockBanner(
                  count: lowStock.length,
                  onTap: () => context.push('/reports'),
                ),
              ],

              const SizedBox(height: 16),

              // Quick Actions
              Text(
                AppLocalizations.of(context)!.dashboardQuickActions,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kForeground,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildQuickAction(
                    'Add customer',
                    Icons.person_add_rounded,
                    const Color(0xFFE3F2FD),
                    Colors.blue,
                    () {},
                  ),
                  const SizedBox(width: 10),
                  _buildQuickAction(
                    'New job card',
                    Icons.add_task_rounded,
                    const Color(0xFFE3F2FD),
                    Colors.blue,
                    () => context.push('/new-job'),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickAction(
                    'Create invoice',
                    Icons.receipt_long_rounded,
                    const Color(0xFFE3F2FD),
                    Colors.blue,
                    () => context.push('/billing'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Recent Bills
              _SectionHeader(
                title: 'Recent bills',
                actionLabel: 'View all',
                onAction: () => context.push('/billing'),
              ),
              const SizedBox(height: 10),

              invoicesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => const Center(
                  child: Text(
                    'Could not load bills',
                    style: TextStyle(color: kMutedForeground, fontSize: 13),
                  ),
                ),
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return const _EmptyBills();
                  }
                  return Column(
                    children: invoices
                        .take(4)
                        .map(
                          (inv) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _BillCard(
                              invoice: inv,
                              onTap: () => context.push('/invoice/${inv.id}'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildStatCard(_StatCard card) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 0.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,  // ADD THIS
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: card.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, size: 18, color: card.color.shade700),
          ),
          const SizedBox(height: 12),  // REPLACE Spacer() with this
          Text(
            card.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: kForeground,
            ),
          ),
          // ... rest unchanged
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color iconBg,
    MaterialColor iconColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder, width: 0.8),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ── Low Stock Banner ─────────────────────────────────────────────────────────
class _LowStockBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _LowStockBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_rounded,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.dashboardLowStockAlert,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.dashboardItemsNeedRestocking(count),
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              AppLocalizations.of(context)!.dashboardActionView,
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: kForeground,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bill Card ────────────────────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _BillCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(invoice.customer?.name ?? '');
    final statusColor = _statusColor(invoice.paymentStatus);
    final statusLabel = _statusLabel(invoice.paymentStatus);
    final amount = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(invoice.grandTotal);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder, width: 0.8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.customer?.name ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: kForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      color: kMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: kForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green.shade700;
      case PaymentStatus.pending:
        return Colors.orange.shade700;
      case PaymentStatus.partial:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _statusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
      default:
        return 'Unknown';
    }
  }
}

// ── Empty Bills placeholder ──────────────────────────────────────────────────
class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: kMutedForeground,
          ),
          const SizedBox(height: 8),
          const Text(
            'No bills yet',
            style: TextStyle(
              fontSize: 13,
              color: kMutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final MaterialColor color;
  final Color iconBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.iconBg,
  });
}
