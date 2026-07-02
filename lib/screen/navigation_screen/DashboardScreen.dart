// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../Models/Billing model/invoice.dart';
import '../../Providers/NavigationProvider.dart';
import '../../Providers/billing_providers.dart';
import '../../Providers/inventoryProvider.dart';
// import '../../Providers/jobsProvider.dart';        // Job card - commented out
import '../../Providers/notificationsProvider.dart';

import '../../core/Theme.dart';
import '../../widgets/StatusBadge.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount  = ref.watch(unreadCountProvider);
    final lowStock     = ref.watch(lowStockItemsProvider);
    // final jobs      = ref.watch(jobsProvider);   // Job card - commented out
    final invoicesAsync = ref.watch(invoiceListProvider);

    final statCards = [
      _StatCard(
        label: "Today's Sales",
        value: '₹31,400',
        sub: '↑ +12% vs yesterday',
        icon: Icons.currency_rupee_rounded,
        color: Colors.blue,
        iconBg: const Color(0xFFE3F2FD),
      ),
      _StatCard(
        label: 'Pending Jobs',
        value: '7',
        sub: '3 urgent',
        icon: Icons.access_time_rounded,
        color: Colors.blue,
        iconBg: const Color(0xFFE3F2FD),
      ),
      _StatCard(
        label: 'Completed',
        value: '19',
        sub: 'Today',
        icon: Icons.check_circle_rounded,
        color: Colors.blue,
        iconBg: const Color(0xFFE3F2FD),
      ),
      _StatCard(
        label: 'Total Customers',
        value: '1,284',
        sub: '↑ +8 this week',
        icon: Icons.people_rounded,
        color: Colors.blue,
        iconBg:const Color(0xFFE3F2FD),
      ),
    ];

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
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
                            style: TextStyle(color: Colors.blue[200], fontSize: 13),
                          ),
                          const Text(
                            'Fradeen Garage',
                            style: TextStyle(
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
                    child: const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Icon(
                            Icons.search_rounded,
                            color: kMutedForeground,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search customer or vehicle...',
                              hintStyle: TextStyle(
                                color: kMutedForeground,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
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

          // ── Body ──────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Stat Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: statCards
                      .map((card) => _buildStatCard(card))
                      .toList(),
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
                const Text(
                  'Quick actions',
                  style: TextStyle(
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
                          (){},
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

                // ── Recent Bills ──────────────────────────────────────────
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
                  error: (e, _) => Center(
                    child: Text(
                      'Could not load bills',
                      style: TextStyle(
                        color: kMutedForeground,
                        fontSize: 13,
                      ),
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
                            onTap: () => context.push(
                              '/billing/invoice/${inv.id}',
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    );
                  },
                ),

                // ── Recent Jobs (COMMENTED OUT) ───────────────────────────
                //
                // const SizedBox(height: 20),
                // _SectionHeader(
                //   title: 'Recent jobs',
                //   actionLabel: 'View all',
                //   onAction: () => ref
                //       .read(navigationProvider.notifier)
                //       .setScreen(AppScreen.jobs),
                // ),
                // const SizedBox(height: 10),
                // ...jobs.take(3).map((job) => Padding(
                //   padding: const EdgeInsets.only(bottom: 8),
                //   child: GarageCard(
                //     onTap: () => AppScreen.jobDetail,
                //     child: Row(
                //       children: [
                //         VehicleIcon(type: job.vehicleType),
                //         const SizedBox(width: 12),
                //         Expanded(
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               Text(job.customer,
                //                   style: const TextStyle(
                //                     fontWeight: FontWeight.w800,
                //                     fontSize: 14,
                //                     color: kForeground,
                //                   )),
                //               const SizedBox(height: 2),
                //               Text('${job.vehicle} · ${job.brand}',
                //                   style: const TextStyle(
                //                     fontSize: 12,
                //                     color: kMutedForeground,
                //                   )),
                //             ],
                //           ),
                //         ),
                //         Column(
                //           crossAxisAlignment: CrossAxisAlignment.end,
                //           children: [
                //             StatusBadge(status: job.status),
                //             const SizedBox(height: 4),
                //             Text(formatCurrency(job.amount),
                //                 style: const TextStyle(
                //                   fontWeight: FontWeight.w800,
                //                   fontSize: 13,
                //                 )),
                //           ],
                //         ),
                //       ],
                //     ),
                //   ),
                // )),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat card builder ──────────────────────────────────────────────────────
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
          const Spacer(),
          Text(
            card.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: kForeground,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            card.label,
            style: const TextStyle(
              fontSize: 11,
              color: kMutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            card.sub,
            style: TextStyle(
              fontSize: 10,
              color: Colors.green.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick action button ────────────────────────────────────────────────────
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

  // ── Greeting helper ────────────────────────────────────────────────────────
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

// ── Low Stock Banner ───────────────────────────────────────────────────────────
class _LowStockBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _LowStockBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        //color: const Color(0xFFFFF8E1),
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
                  'Low stock alert',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count items need restocking',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'View',
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

// ── Section Header ────────────────────────────────────────────────────────────
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

// ── Bill Card ─────────────────────────────────────────────────────────────────
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
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
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
            // Info
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
                    '${invoice.invoiceNumber}  ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: kMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            // Amount + Badge
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

// ── Empty Bills placeholder ───────────────────────────────────────────────────
class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 36, color: kMutedForeground),
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

// ── _StatCard data class ──────────────────────────────────────────────────────
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