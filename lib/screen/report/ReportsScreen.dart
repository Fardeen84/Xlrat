// lib/screen/report/ReportsScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../core/Theme.dart';
import '../../widgets/StatusBadge.dart';
import '../../providers/billing_providers.dart';
import '../../models/billing_model/invoice.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _period = 'weekly';

  final _topCustomers = [
    ('Mohammed Irfan', 87600, 12, 'MI'),
    ('Arun Nair', 62100, 9, 'AN'),
    ('Rajesh Kumar', 48500, 7, 'RK'),
    ('Priya Sharma', 23200, 5, 'PS'),
  ];

  final _topParts = [
    ('Engine Oil 10W-40', 148, 76960),
    ('Oil Filter', 94, 14100),
    ('Brake Pad Set', 38, 41800),
    ('Air Filter', 72, 15840),
  ];

  final _jobStatus = [
    ('Completed', 68, const Color(0xFF43A047)),
    ('In Progress', 22, Color(0xFF1565C0)),
    ('Pending', 10, Color(0xFFFB8C00)),
  ];

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
                Text(AppLocalizations.of(context)!.reportsTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
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
                              color: isSelected ? Colors.white : kMutedForeground,
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
              loading: () => const Center(child: CircularProgressIndicator(color: kPrimary)),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to load report data: $err',
                    style: const TextStyle(color: kRed, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (invoices) {
                // Calculate metrics dynamically based on actual data
                final double totalRevenue = invoices.fold(0, (sum, inv) => sum + inv.grandTotal);
                final int totalJobs = invoices.length;
                final double avgTicket = totalJobs > 0 ? totalRevenue / totalJobs : 0;

                final chartData = _getChartData(invoices);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        _statCard(_formatCurrencyCompact(totalRevenue), 'Revenue', '+18%'),
                        const SizedBox(width: 10),
                        _statCard('$totalJobs', 'Jobs Done', '+12%'),
                        const SizedBox(width: 10),
                        _statCard(_formatCurrencyCompact(avgTicket), 'Avg Ticket', '+5%'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Revenue Bar Chart
                    GarageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Revenue Trend',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 180,
                            child: _FlBarChart(data: chartData),
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
                          const Text('Job Status Overview',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CustomPaint(
                                  painter: _DonutPainter(data: _jobStatus),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: _jobStatus.map((s) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: s.$3,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(s.$1,
                                              style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                                        ),
                                        Text('${s.$2}%',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kForeground)),
                                      ],
                                    ),
                                  ),
                                  ).toList(),
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
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Text('Top Customers',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
                          ),
                          ..._topCustomers.asMap().entries.map((entry) {
                            final i = entry.key;
                            final c = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: i == 0 ? const BorderSide(color: kBorder, width: 0.5) : BorderSide.none,
                                  bottom: const BorderSide(color: kBorder, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text('${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kMutedForeground)),
                                  const SizedBox(width: 12),
                                  AvatarWidget(initials: c.$4, size: 36),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kForeground)),
                                        Text('${c.$3} visits', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                      ],
                                    ),
                                  ),
                                  Text(formatCurrency(c.$2),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary)),
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
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Text('Most Used Parts',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
                          ),
                          ..._topParts.asMap().entries.map((entry) {
                            final p = entry.value;
                            final pct = (p.$2 / 148).clamp(0.0, 1.0);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(p.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kForeground)),
                                      Text(formatCurrency(p.$3),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: kMuted,
                                            valueColor: const AlwaysStoppedAnimation(kPrimary),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${p.$2} units',
                                          style: const TextStyle(fontSize: 10, color: kMutedForeground)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kForeground)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: kMutedForeground)),
            const SizedBox(height: 2),
            Text(change, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
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

// ── FL Bar Chart Integration ──────────────────────────────────────────────────

class _FlBarChart extends StatelessWidget {
  final List<(String, double)> data;
  const _FlBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: kMutedForeground, fontSize: 13),
        ),
      );
    }

    final double maxVal = data.map((d) => d.$2).reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal == 0 ? 1000 : maxVal * 1.25;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => kCard,
            tooltipBorder: const BorderSide(color: kBorder, width: 1),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.round()}',
                const TextStyle(
                  color: kForeground,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
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
                      style: const TextStyle(
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
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final val = entry.value.$2;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: kPrimary,
                width: 14,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Donut Chart Painter ───────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<(String, int, Color)> data;
  _DonutPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0, (sum, d) => sum + d.$2);
    double startAngle = -1.5708; // -90 degrees

    for (final d in data) {
      final sweep = (d.$2 / total) * 6.2832;
      final paint = Paint()
        ..color = d.$3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22;

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width - 22,
          height: size.height - 22,
        ),
        startAngle,
        sweep - 0.05,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}