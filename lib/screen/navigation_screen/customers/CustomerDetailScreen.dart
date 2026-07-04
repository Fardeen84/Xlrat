// lib/screens/customers/customer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../models/CustomerModelas.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../models/billing_model/InvoiceItem.dart';
import '../../../models/billing_model/invoice.dart';
import '../../../providers/customersProvider.dart';
import '../../../providers/billing_providers.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  int _tabIndex = 0;

  String summarizeItems(List<InvoiceItem> items) {
    if (items.isEmpty) return 'No items';
    return items.map((i) => i.itemName).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customersProvider).firstWhere(
          (c) => c.id == widget.customerId,
          orElse: () => Customer(
            id: widget.customerId,
            name: 'Customer #${widget.customerId}',
            phone: '',
            vehicles: 0,
            lastVisit: '',
            avatar: '?',
            totalSpent: 0,
            pending: 0,
          ),
        );

    final invoicesAsync = ref.watch(invoicesByCustomerProvider(widget.customerId));
    final invoices = invoicesAsync.value ?? [];

    final uniqueVehiclesCount = invoices.map((i) => i.vehicle?.vehicleNumber).whereType<String>().toSet().length;
    final totalSpent = invoices.fold<double>(0, (sum, i) => sum + i.grandTotal).round();
    final pending = invoices.where((i) => i.paymentStatus != PaymentStatus.paid).fold<double>(0, (sum, i) => sum + i.grandTotal).round();

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
                              child: Center(
                                child: Text(
                                  customer.avatar.isNotEmpty ? customer.avatar : (customer.name.length >= 2 ? customer.name.substring(0, 2).toUpperCase() : '?'),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.phone_rounded, size: 12, color: Colors.blue[200]),
                                    const SizedBox(width: 4),
                                    Text('+91 ${customer.phone}',
                                        style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                                  ]),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _chip('$uniqueVehiclesCount Vehicle${uniqueVehiclesCount == 1 ? '' : 's'}'),
                                      const SizedBox(width: 8),
                                      _chip('Since ${customer.lastVisit.isNotEmpty ? customer.lastVisit : '2024'}'),
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
                            Expanded(child: _miniStat('Total Spent', formatCurrency(totalSpent))),
                            const SizedBox(width: 10),
                            Expanded(child: _miniStat('Pending', pending > 0 ? formatCurrency(pending) : '—')),
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

                  invoicesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('Error: $err', style: const TextStyle(color: kRed))),
                    ),
                    data: (invoicesList) {
                      if (invoicesList.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.receipt_long_rounded, size: 22, color: kMutedForeground),
                              ),
                              const SizedBox(height: 10),
                              const Text('Koi invoice nahi mila', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
                              const SizedBox(height: 4),
                              const Text('Is customer ke liye koi record nahi hai', style: TextStyle(fontSize: 12, color: kMutedForeground)),
                            ],
                          ),
                        );
                      }

                      final uniqueVehicles = <String, BillingVehicle>{};
                      for (final inv in invoicesList) {
                        final veh = inv.vehicle;
                        if (veh != null && veh.vehicleNumber.isNotEmpty) {
                          uniqueVehicles[veh.vehicleNumber] = veh;
                        }
                      }
                      final vehiclesList = uniqueVehicles.values.toList();

                      if (_tabIndex == 0) {
                        if (vehiclesList.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('Vehicles data available nahi hai', style: TextStyle(color: kMutedForeground, fontSize: 13)),
                          );
                        }
                        return Column(
                          children: vehiclesList.map((v) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GarageCard(
                              child: Row(
                                children: [
                                  const VehicleIcon(type: 'car'),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${v.vehicleBrand} ${v.vehicleModel}'.trim().isNotEmpty
                                                  ? '${v.vehicleBrand} ${v.vehicleModel}'
                                                  : 'Unknown Vehicle',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                            ),
                                            Text(v.fuelType.isNotEmpty ? v.fuelType : 'Petrol', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(v.vehicleNumber, style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        );
                      }

                      if (_tabIndex == 1) {
                        return Column(
                          children: invoicesList.map((inv) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GarageCard(
                              onTap: () => context.push('/invoice/${inv.id}'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('${DateFormat('dd MMM yyyy').format(inv.invoiceDate)} · ${inv.vehicle?.vehicleBrand ?? ''} ${inv.vehicle?.vehicleModel ?? ''}'.trim(),
                                          style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(formatCurrency(inv.grandTotal.round()), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      StatusBadge(status: inv.paymentStatus == PaymentStatus.paid ? 'completed' : 'pending'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        );
                      }

                      if (_tabIndex == 2) {
                        return Column(
                          children: List.generate(invoicesList.length, (i) {
                            final inv = invoicesList[i];
                            final dateStr = DateFormat('dd MMM yyyy').format(inv.invoiceDate);
                            final description = summarizeItems(inv.items);
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
                                  if (i < invoicesList.length - 1)
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
                                          Text(dateStr, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                          const SizedBox(height: 2),
                                          Text(description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text(formatCurrency(inv.grandTotal.round()),
                                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),

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