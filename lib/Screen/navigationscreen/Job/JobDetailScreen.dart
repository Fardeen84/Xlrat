// lib/screens/jobs/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../widgets/StatusBadge.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  int _tabIndex = 0;

  static const _parts = [
    ('Engine Oil 10W-40 (1L)', 4, 520, 2080),
    ('Oil Filter – Universal', 1, 150, 150),
    ('Air Filter – Maruti Swift', 1, 220, 220),
  ];

  static const _timeline = [
    (Icons.receipt_long_rounded, '9:30 AM', 'Job card created', 'Advisor Ravi'),
    (Icons.visibility_rounded, '10:15 AM', 'Vehicle inspection started', 'Suresh K.'),
    (Icons.inventory_2_rounded, '11:00 AM', 'Parts ordered from inventory', 'Suresh K.'),
    (Icons.build_rounded, '2:00 PM', 'Repair in progress', 'Suresh K.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          // App Bar
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
                  onPressed: () => context.go('/jobs'),
                ),
                const Expanded(
                  child: Text('JC-2024-0156',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kForeground)),
                ),
                const Icon(Icons.edit_rounded, color: kForeground, size: 18),
                const SizedBox(width: 10),
                const StatusBadge(status: 'in-progress'),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Vehicle Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0288D1)]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Vehicle', style: TextStyle(color: Colors.blue[200], fontSize: 11, fontWeight: FontWeight.w600)),
                              const Text('MH12 AB 1234',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('Maruti Swift', style: TextStyle(color: Colors.blue[200], fontSize: 12)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _infoChip('Mechanic', 'Suresh K.')),
                            const SizedBox(width: 8),
                            Expanded(child: _infoChip('Date', '23 Jun')),
                            const SizedBox(width: 8),
                            Expanded(child: _infoChip('Amount', '₹8,500')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  GarageTabBar(
                    tabs: const ['Details', 'Parts', 'Timeline'],
                    selectedIndex: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),
                  const SizedBox(height: 14),

                  if (_tabIndex == 0) ...[
                    GarageCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('CUSTOMER COMPLAINT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        const Text('Engine noise, oil leak from left side',
                            style: TextStyle(fontSize: 14, color: kForeground, height: 1.5)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    GarageCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('LABOUR CHARGES',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.8)),
                        const SizedBox(height: 10),
                        ...[ ('Engine inspection', 800), ('Oil change service', 400), ('Filter replacement', 200) ]
                            .map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.$1, style: const TextStyle(fontSize: 13)),
                              Text(formatCurrency(l.$2), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )),
                        const Divider(color: kBorder),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Labour Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('₹1,400', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kPrimary)),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Mark Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/billing'),
                          icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: const Text('Generate Bill'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ]),
                  ],

                  if (_tabIndex == 1) ...[
                    ..._parts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GarageCard(
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2_rounded, size: 18, color: kPrimary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('Qty: ${p.$2} × ${formatCurrency(p.$3)}',
                                  style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                            ],
                          )),
                          Text(formatCurrency(p.$4),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ]),
                      ),
                    )),
                    const Divider(color: kBorder),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Parts Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          Text('₹2,450', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimary)),
                        ],
                      ),
                    ),
                  ],

                  if (_tabIndex == 2)
                    ..._timeline.asMap().entries.map((entry) {
                      final i = entry.key;
                      final t = entry.value;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDBEAFE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(t.$1, size: 16, color: kPrimary),
                            ),
                            if (i < _timeline.length - 1)
                              Container(width: 2, height: 50, color: kBorder),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(t.$3, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('${t.$2} · by ${t.$4}',
                                      style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/billing'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('Generate Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.share_rounded, color: kForeground, size: 20),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blue[200], fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}