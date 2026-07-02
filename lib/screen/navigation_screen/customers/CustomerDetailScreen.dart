// lib/screens/customers/customer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../widgets/StatusBadge.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  int _tabIndex = 0;

  static const _vehicles = [
    ('MH12 AB 1234', 'Maruti', 'Swift VXI', '2019', '44,200', '15 Jan 2024', 'car'),
    ('MH12 XY 9876', 'Royal Enfield', 'Bullet 350', '2021', '18,700', '10 Mar 2024', 'bike'),
  ];

  static const _history = [
    ('23 Jun 2024', 'Engine oil change, filter replacement', 1200),
    ('15 Jan 2024', 'Full service + AC gas refill', 8500),
    ('8 Oct 2023', 'Brake pads replacement', 3200),
    ('22 Jul 2023', 'Tyre rotation, wheel balancing', 800),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: kCard,
            elevation: 0,
            surfaceTintColor: kCard,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
              onPressed: () => context.go('/customers'),
            ),
            title: const Text('Customer Details',
                style: TextStyle(fontWeight: FontWeight.w800, color: kForeground, fontSize: 16)),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: kForeground),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              ),
                              child: const Center(
                                child: Text('RK',
                                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Rajesh Kumar',
                                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.phone_rounded, size: 12, color: Colors.blue[200]),
                                    const SizedBox(width: 4),
                                    Text('+91 9876543210',
                                        style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                                  ]),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _chip('2 Vehicles'),
                                      const SizedBox(width: 8),
                                      _chip('Since 2021'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _miniStat('Total Spent', '₹48,500')),
                            const SizedBox(width: 10),
                            Expanded(child: _miniStat('Pending', '—')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Action Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/new-job'),
                          icon: const Icon(Icons.assignment_rounded, size: 16),
                          label: const Text('New Job Card'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/billing'),
                          icon: const Icon(Icons.receipt_long_rounded, size: 16, color: kPrimary),
                          label: const Text('Invoice', style: TextStyle(color: kPrimary)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: kPrimary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorder),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.chat_rounded, color: kForeground, size: 20),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  GarageTabBar(
                    tabs: const ['Vehicles', 'Invoices', 'History'],
                    selectedIndex: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),

                  const SizedBox(height: 14),

                  if (_tabIndex == 0)
                    ..._vehicles.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GarageCard(
                        child: Row(
                          children: [
                            VehicleIcon(type: v.$7),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${v.$2} ${v.$3}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                      Text(v.$4, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(v.$1, style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.speed_rounded, size: 11, color: kMutedForeground),
                                    const SizedBox(width: 3),
                                    Text('${v.$5} km', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.calendar_today_rounded, size: 11, color: kMutedForeground),
                                    const SizedBox(width: 3),
                                    Text(v.$6, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                  if (_tabIndex == 1)
                    ...[
                      ('JC-2024-0156', '23 Jun 2024', 'Maruti Swift', 8500, 'in-progress'),
                      ('JC-2024-0154', '22 Jun 2024', 'Toyota Innova', 14200, 'completed'),
                      ('JC-2024-0152', '21 Jun 2024', 'Hyundai i20', 9800, 'in-progress'),
                    ].map((job) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GarageCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(job.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${job.$2} · ${job.$3}', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                            ]),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(formatCurrency(job.$4), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 4),
                              StatusBadge(status: job.$5),
                            ]),
                          ],
                        ),
                      ),
                    )),

                  if (_tabIndex == 2)
                    ..._history.asMap().entries.map((entry) {
                      final i = entry.key;
                      final h = entry.value;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.check_circle_rounded, size: 18, color: kGreen),
                            ),
                            if (i < _history.length - 1)
                              Container(width: 2, height: 48, color: kBorder),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GarageCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h.$1, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                    const SizedBox(height: 2),
                                    Text(h.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(formatCurrency(h.$3),
                                        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                  ],
                                ),
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
        ],
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _miniStat(String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.blue[200], fontSize: 11)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    ),
  );
}