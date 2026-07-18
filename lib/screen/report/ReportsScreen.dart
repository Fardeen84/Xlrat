// lib/screen/report/ReportsScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../core/Theme.dart';
import '../../widgets/StatusBadge.dart';
import '../../providers/billing_providers.dart';
import '../../models/billing_model/invoice.dart';
import '../../providers/jobsProvider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/backfill_migration.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _period = 'weekly';

  // Grouping logic for the chart
  List<(String, double)> _getChartData(List<Invoice> invoices) {
    final now = DateTime.now();
    final List<(String, double)> chartData = [];

    if (_period == 'daily' || _period == 'weekly') {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayLabel = DateFormat('E').format(date); // Mon, Tue...

        double total = 0;
        for (final inv in invoices) {
          if (inv.invoiceDate.year == date.year &&
              inv.invoiceDate.month == date.month &&
              inv.invoiceDate.day == date.day) {
            total += inv.grandTotal;
          }
        }
        chartData.add((dayLabel, total));
      }
    } else {
      // Last 6 months
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthLabel = DateFormat('MMM').format(date); // Jan, Feb...

        double total = 0;
        for (final inv in invoices) {
          if (inv.invoiceDate.year == date.year &&
              inv.invoiceDate.month == date.month) {
            total += inv.grandTotal;
          }
        }
        chartData.add((monthLabel, total));
      }
    }
    return chartData;
  }

  String _formatCurrencyCompact(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(reportsInvoicesProvider);
    final topCustomersAsync = ref.watch(topCustomersProvider);
    final topPartsAsync = ref.watch(topPartsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          // Header
          Container(
            color: kCard,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.reportsTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kForeground,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_backup_restore_rounded, color: kPrimary),
                      tooltip: 'Backfill Reports Stats (One-time)',
                      onPressed: () async {
                        try {
                          final garageId = ref.read(profileProvider).garageId;
                          await runOneTimeStatsBackfill(garageId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reports backfill completed successfully!'),
                                backgroundColor: kGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Backfill failed: $e'),
                                backgroundColor: kRed,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['daily', 'weekly', 'monthly'].map((p) {
                    final isSelected = _period == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _period = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimary : kMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _localPeriod(context, p),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : kMutedForeground,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Expanded(
            child: invoicesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: kPrimary),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to load report data: $err',
                    style: const TextStyle(
                      color: kRed,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (invoices) {
                // Calculate metrics dynamically based on actual data
                final double totalRevenue = invoices.fold(
                  0,
                  (sum, inv) => sum + inv.grandTotal,
                );
                final int totalJobs = invoices.length;
                final double avgTicket = totalJobs > 0
                    ? totalRevenue / totalJobs
                    : 0;

                final chartData = _getChartData(invoices);
                final topCustomers = topCustomersAsync.value ?? [];
                final topParts = topPartsAsync.value ?? [];
                final jobCounts = ref.watch(reportsJobStatusCountsProvider).value ?? {};
                final completedCount = jobCounts['completed'] ?? 0;
                final inProgressCount = jobCounts['in-progress'] ?? 0;
                final pendingCount = jobCounts['pending'] ?? 0;
                final totalJobsCount =
                    completedCount + inProgressCount + pendingCount;

                final completedPct = totalJobsCount > 0
                    ? ((completedCount / totalJobsCount) * 100).round()
                    : 0;
                final inProgressPct = totalJobsCount > 0
                    ? ((inProgressCount / totalJobsCount) * 100).round()
                    : 0;
                final pendingPct = totalJobsCount > 0
                    ? (100 - completedPct - inProgressPct).clamp(0, 100)
                    : 0;

                final jobStatusData = [
                  ('Completed', completedPct, const Color(0xFF43A047)),
                  ('In Progress', inProgressPct, const Color(0xFFFDB913)),
                  ('Pending', pendingPct, const Color(0xFFFB8C00)),
                ];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        _statCard(
                          _formatCurrencyCompact(totalRevenue),
                          'Revenue',
                          '+18%',
                        ),
                        const SizedBox(width: 10),
                        _statCard('$totalJobs', 'Jobs Done', '+12%'),
                        const SizedBox(width: 10),
                        _statCard(
                          _formatCurrencyCompact(avgTicket),
                          'Avg Ticket',
                          '+5%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Revenue Line Chart
                    GarageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Revenue Trend',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kForeground,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: _FlLineChart(data: chartData),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Job Status
                    GarageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Status Overview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kForeground,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (totalJobsCount == 0)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No job data available',
                                  style: TextStyle(color: kMutedForeground),
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: PieChart(
                                    PieChartData(
                                      pieTouchData: PieTouchData(
                                        touchCallback:
                                            (
                                              FlTouchEvent event,
                                              pieTouchResponse,
                                            ) {
                                              if (!event
                                                      .isInterestedForInteractions ||
                                                  pieTouchResponse == null ||
                                                  pieTouchResponse
                                                          .touchedSection ==
                                                      null) {
                                                return;
                                              }
                                              final touchedIndex =
                                                  pieTouchResponse
                                                      .touchedSection!
                                                      .touchedSectionIndex;
                                              if (touchedIndex >= 0 &&
                                                  touchedIndex <
                                                      jobStatusData.length) {
                                                final status =
                                                    jobStatusData[touchedIndex]
                                                        .$1
                                                        .toLowerCase();
                                                final filterVal =
                                                    status == 'in progress'
                                                    ? 'in-progress'
                                                    : status;
                                                ref
                                                        .read(
                                                          jobFilterProvider
                                                              .notifier,
                                                        )
                                                        .state =
                                                    filterVal;
                                                context.go('/jobs');
                                              }
                                            },
                                      ),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 36,
                                      sections: jobStatusData.map((s) {
                                        return PieChartSectionData(
                                          color: s.$3,
                                          value: s.$2.toDouble(),
                                          title: '${s.$2}%',
                                          radius: 20,
                                          titleStyle: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: jobStatusData.map((s) {
                                      final status = s.$1.toLowerCase();
                                      final filterVal = status == 'in progress'
                                          ? 'in-progress'
                                          : status;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          onTap: () {
                                            ref
                                                    .read(
                                                      jobFilterProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                filterVal;
                                            context.go('/jobs');
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: s.$3,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    s.$1,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: kMutedForeground,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${s.$2}%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: kForeground,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Customers
                    GarageCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Text(
                              'Top Customers',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: kForeground,
                              ),
                            ),
                          ),
                          if (topCustomers.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No customer data available',
                                  style: TextStyle(color: kMutedForeground),
                                ),
                              ),
                            )
                          else
                            ...topCustomers.asMap().entries.map((entry) {
                              final i = entry.key;
                              final c = entry.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: i == 0
                                        ? BorderSide(color: kBorder, width: 0.5)
                                        : BorderSide.none,
                                    bottom: BorderSide(
                                      color: kBorder,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: kMutedForeground,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    AvatarWidget(initials: c.$4, size: 36),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.$1,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: kForeground,
                                            ),
                                          ),
                                          Text(
                                            '${c.$3} visits',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: kMutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(c.$2.round()),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: kPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Most Used Parts
                    GarageCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Text(
                              'Most Used Parts',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: kForeground,
                              ),
                            ),
                          ),
                          if (topParts.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No parts data available',
                                  style: TextStyle(color: kMutedForeground),
                                ),
                              ),
                            )
                          else
                            ...topParts.asMap().entries.map((entry) {
                              final p = entry.value;
                              final maxQty = topParts.isNotEmpty
                                  ? topParts.first.$2
                                  : 1.0;
                              final pct = maxQty > 0
                                  ? (p.$2 / maxQty).clamp(0.0, 1.0)
                                  : 0.0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: kBorder,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          p.$1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: kForeground,
                                          ),
                                        ),
                                        Text(
                                          formatCurrency(p.$3.round()),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: kPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              backgroundColor: kMuted,
                                              valueColor:
                                                  const AlwaysStoppedAnimation(
                                                    kPrimary,
                                                  ),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${p.$2.round()} units',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: kMutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, String change) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: kForeground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: kMutedForeground),
            ),
            const SizedBox(height: 2),
            Text(
              change,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localPeriod(BuildContext context, String p) {
    final l10n = AppLocalizations.of(context)!;
    switch (p) {
      case 'daily':
        return l10n.reportsPeriodDaily;
      case 'weekly':
        return l10n.reportsPeriodWeekly;
      case 'monthly':
        return l10n.reportsPeriodMonthly;
      default:
        return p;
    }
  }
}

// ── FL Line Chart Integration ──────────────────────────────────────────────────

class _FlLineChart extends StatelessWidget {
  final List<(String, double)> data;
  const _FlLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: kMutedForeground, fontSize: 13),
        ),
      );
    }

    final double maxVal = data.map((d) => d.$2).reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal == 0 ? 1000 : maxVal * 1.15;

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.$2);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 250,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: kBorder, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[index].$1,
                      style: TextStyle(
                        color: kMutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => kCard,
            tooltipBorder: BorderSide(color: kBorder, width: 1),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dateLabel = data[spot.x.toInt()].$1;
                return LineTooltipItem(
                  '$dateLabel\n₹${spot.y.round()}',
                  TextStyle(
                    color: kForeground,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: kPrimary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: kPrimary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
