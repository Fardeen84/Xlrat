// lib/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/StatusBadge.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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

  final _monthlyData = [
    ('Jan', 185000),
    ('Feb', 210000),
    ('Mar', 198000),
    ('Apr', 245000),
    ('May', 278000),
    ('Jun', 312000),
  ];

  final _jobStatus = [
    ('Completed', 68, const Color(0xFF43A047)),
    ('In Progress', 22, Color(0xFF1565C0)),
    ('Pending', 10, Color(0xFFFB8C00)),
  ];

  @override
  Widget build(BuildContext context) {
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
                const Text('Reports & Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
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
                            p[0].toUpperCase() + p.substring(1),
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Stats Row
                Row(
                  children: [
                    _statCard('₹1.36L', 'Revenue', '+18%'),
                    const SizedBox(width: 10),
                    _statCard('86', 'Jobs Done', '+12%'),
                    const SizedBox(width: 10),
                    _statCard('₹1,581', 'Avg Ticket', '+5%'),
                  ],
                ),
                const SizedBox(height: 16),

                // Revenue Bar Chart (custom painted)
                GarageCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue Trend',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: _BarChart(data: _monthlyData),
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
                              )).toList(),
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
                        final i = entry.key;
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
}

// ── Simple Bar Chart ──────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<(String, int)> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((d) => d.$2).reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final pct = d.$2 / maxVal;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 120 * pct,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(d.$1, style: const TextStyle(fontSize: 10, color: kMutedForeground)),
              ],
            ),
          ),
        );
      }).toList(),
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