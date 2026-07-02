// lib/screens/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../Models/CustomerModelas.dart';
import '../../../Models/Vehicle.dart';
import '../../../Providers/NavigationProvider.dart';
import '../../../Providers/customersProvider.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';


class CustomersScreen extends ConsumerWidget {

  const CustomersScreen({super.key,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredCustomersProvider);

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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Customers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GarageSearchBar(
                  hint: 'Search by name or phone...',
                  onChanged: (v) => ref.read(customerSearchProvider.notifier).state = v,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: filtered.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${filtered.length} customers',
                        style: const TextStyle(fontSize: 12, color: kMutedForeground, fontWeight: FontWeight.w600)),
                  );
                }
                final customer = filtered[i - 1];
                return _CustomerCard(customer: customer, onTap: () {
                  ref.read(selectedCustomerProvider.notifier).state = customer;
                  AppScreen.customerDetail;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GarageCard(
      onTap: onTap,
      child: Row(
        children: [
          AvatarWidget(initials: customer.avatar),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 11, color: kMutedForeground),
                    const SizedBox(width: 3),
                    Text(customer.phone, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.directions_car_rounded, size: 11, color: kMutedForeground),
                    const SizedBox(width: 3),
                    Text('${customer.vehicles} vehicle${customer.vehicles > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                    const Text(' · ', style: TextStyle(color: kMutedForeground, fontSize: 11)),
                    Text(customer.lastVisit, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (customer.pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                  child: Text('₹${(customer.pending / 1000).toStringAsFixed(1)}k due',
                      style: const TextStyle(color: kRed, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded, color: kMutedForeground, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Customer Detail Screen ───────────────────────────────────────────────────

class CustomerDetailScreen extends ConsumerStatefulWidget {

  const CustomerDetailScreen({super.key,});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  int _tabIndex = 0;

  final vehicles = [
    const Vehicle(id: 1, number: 'MH12 AB 1234', brand: 'Maruti', model: 'Swift VXI', year: '2019', km: '44,200', lastService: '15 Jan 2024', type: 'car'),
    const Vehicle(id: 2, number: 'MH12 XY 9876', brand: 'Royal Enfield', model: 'Bullet 350', year: '2021', km: '18,700', lastService: '10 Mar 2024', type: 'bike'),
  ];

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(selectedCustomerProvider) ?? mockCustomers[0];

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: kCard,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
              onPressed: () => AppScreen.customers,
            ),
            title: const Text('Customer Details'),
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
                    padding: const EdgeInsets.all(18),
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
                              child: Center(
                                child: Text(customer.avatar, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded, size: 12, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(customer.phone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _whiteChip('${customer.vehicles} Vehicles'),
                                      const SizedBox(width: 6),
                                      _whiteChip('Since 2021'),
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
                            Expanded(child: _miniStat('Total Spent', formatCurrency(customer.totalSpent))),
                            const SizedBox(width: 10),
                            Expanded(child: _miniStat('Pending', customer.pending > 0 ? formatCurrency(customer.pending) : '—')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => AppScreen.newJob,
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
                          onPressed: () => AppScreen.billing,
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
                  if (_tabIndex == 0) ...vehicles.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GarageCard(
                      child: Row(
                        children: [
                          VehicleIcon(type: v.type),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${v.brand} ${v.model}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    Text(v.year, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(v.number, style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.speed_rounded, size: 11, color: kMutedForeground),
                                    const SizedBox(width: 3),
                                    Text('${v.km} km', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.calendar_today_rounded, size: 11, color: kMutedForeground),
                                    const SizedBox(width: 3),
                                    Text(v.lastService, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

                  if (_tabIndex == 1) ...mockJobs.take(3).map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GarageCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${job.date} · ${job.brand}', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatCurrency(job.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 4),
                              StatusBadge(status: job.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),

                  if (_tabIndex == 2)
                    ...List.generate(4, (i) {
                      final items = [
                        ('23 Jun 2024', 'Engine oil change, filter replacement', 1200),
                        ('15 Jan 2024', 'Full service + AC gas refill', 8500),
                        ('8 Oct 2023', 'Brake pads replacement', 3200),
                        ('22 Jul 2023', 'Tyre rotation, wheel balancing', 800),
                      ];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
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
                              if (i < 3) Container(width: 2, height: 40, color: kBorder),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GarageCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(items[i].$1, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                    const SizedBox(height: 2),
                                    Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(formatCurrency(items[i].$3), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
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

  Widget _whiteChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}