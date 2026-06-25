// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../Providers/NavigationProvider.dart';
import '../../Providers/inventoryProvider.dart';
import '../../Providers/jobsProvider.dart';
import '../../Providers/notificationsProvider.dart';
import '../../Providers/revenueDataProvider.dart';
import '../../core/Theme.dart';
import '../../widgets/StatusBadge.dart';


class DashboardScreen extends ConsumerWidget {

  const DashboardScreen({super.key, });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final lowStock = ref.watch(lowStockItemsProvider);
    final jobs = ref.watch(jobsProvider);
    final revenue = ref.watch(revenueDataProvider);

    final statCards = [
      _StatCard(label: "Today's Sales", value: '₹31,400', sub: '+12% vs yesterday', icon: Icons.currency_rupee_rounded, color: Colors.blue),
      _StatCard(label: 'Pending Jobs', value: '7', sub: '3 urgent', icon: Icons.access_time_rounded, color: Colors.blue),
      _StatCard(label: 'Completed', value: '19', sub: 'Today', icon: Icons.check_circle_rounded, color: Colors.blue),
      _StatCard(label: 'Total Customers', value: '1,284', sub: '+8 this week', icon: Icons.people_rounded, color: Colors.blue),
    ];

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
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
                          Text('Good morning,', style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                          const Text('Fradeen Garage', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {context.push("/notifications");},
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
                              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(10)),
                                  child: Center(
                                    child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
                    ]),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 14),
                          child: Icon(Icons.search_rounded, color: kMutedForeground, size: 20),
                        ),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search customer or vehicle...',
                              hintStyle: TextStyle(color: kMutedForeground, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  children: statCards.map((card) => _buildStatCard(card)).toList(),
                ),

                if (lowStock.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.warning_rounded, color: Colors.orange.shade700, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Low Stock Alert', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange.shade900, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${lowStock.length} items need restocking', style: TextStyle(color: Colors.orange.shade700, fontSize: 11)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push("/reports"),
                          child: Text('View', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w800, fontSize: 12, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Quick Actions
                const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildQuickAction('Add Customer', Icons.person_add_rounded, Colors.blue, () => AppScreen.customers),
                    const SizedBox(width: 10),
                    _buildQuickAction('New Job Card', Icons.add_task_rounded, Colors.blue, () => context.push("/new-job")),
                    const SizedBox(width: 10),
                    _buildQuickAction('Create Invoice', Icons.receipt_long_rounded, Colors.blue, () =>context.push("/billing")),
                  ],
                ),

                const SizedBox(height: 16),
                // Revenue Chart
                GarageCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Weekly Revenue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                            child: const Text('This Week', style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 10000,
                              getDrawingHorizontalLine: (_) => FlLine(color: kBorder, strokeWidth: 0.8),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  getTitlesWidget: (v, _) => Text('₹${(v / 1000).toInt()}k', style: const TextStyle(fontSize: 10, color: kMutedForeground)),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    final idx = v.toInt();
                                    if (idx >= 0 && idx < days.length) {
                                      return Text(days[idx], style: const TextStyle(fontSize: 10, color: kMutedForeground));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(revenue.length, (i) => FlSpot(i.toDouble(), revenue[i].revenue.toDouble())),
                                isCurved: true,
                                color: kPrimary,
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [kPrimary.withOpacity(0.15), kPrimary.withOpacity(0)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SectionHeader(title: 'Recent Jobs', action: 'View All', onAction: () => AppScreen.jobs),
                const SizedBox(height: 10),
                ...jobs.take(3).map((job) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GarageCard(
                    onTap: () => AppScreen.jobDetail,
                    child: Row(
                      children: [
                        VehicleIcon(type: job.vehicleType),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                              const SizedBox(height: 2),
                              Text('${job.vehicle} · ${job.brand}', style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: job.status),
                            const SizedBox(height: 4),
                            Text(formatCurrency(job.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatCard card) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, size: 18, color: card.color.shade700),
          ),
          const Spacer(),
          Text(card.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kForeground)),
          const SizedBox(height: 1),
          Text(card.label, style: const TextStyle(fontSize: 11, color: kMutedForeground, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(card.sub, style: TextStyle(fontSize: 10, color: Colors.green.shade600, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, MaterialColor color, VoidCallback onTap) {
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
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 22, color: color.shade700),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kForeground)),
            ],
          ),
        ),
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

  const _StatCard({required this.label, required this.value, required this.sub, required this.icon, required this.color});
}