// lib/screens/other_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../Models/CustomerModelas.dart';
import '../../../Models/InventoryItem.dart';
import '../../../Providers/NavigationProvider.dart';
import '../../../Providers/inventoryProvider.dart';
import '../../../Providers/jobsProvider.dart';
import '../../../Providers/notificationsProvider.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';

// // ─── Inventory Screen ─────────────────────────────────────────────────────────
//
class InventoryScreen extends ConsumerWidget {

  const InventoryScreen({super.key, });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredInventoryProvider);
    final lowStockItems = ref.watch(lowStockItemsProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            color: kCard,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16, right: 16, bottom: 12,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
                    Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, color: kMutedForeground, size: 20),
                        const SizedBox(width: 14),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GarageSearchBar(
                  hint: 'Search parts or category...',
                  onChanged: (v) => ref.read(inventorySearchProvider.notifier).state = v,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                if (lowStockItems.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('${lowStockItems.length} items below minimum stock',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InventoryCard(item: item),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GarageCard(
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: item.isLowStock ? const Color(0xFFFFEBEE) : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_rounded, size: 22,
                color: item.isLowStock ? kRed : kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kForeground)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(6)),
                      child: Text(item.category, style: const TextStyle(fontSize: 10, color: kMutedForeground, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text('SKU: ${item.sku}', style: const TextStyle(fontSize: 10, color: kMutedForeground)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Sell: ${formatCurrency(item.selling)}', style: const TextStyle(fontSize: 11, color: kForeground, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('Cost: ${formatCurrency(item.purchase)}', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.stock} ${item.unit}',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: item.isLowStock ? kRed : kForeground,
                ),
              ),
              const SizedBox(height: 4),
              if (item.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Low Stock', style: TextStyle(fontSize: 10, color: kRed, fontWeight: FontWeight.w700)),
                )
              else
                Text('Min: ${item.minStock}', style: const TextStyle(fontSize: 10, color: kMutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}
//
// // ─── Notifications Screen ─────────────────────────────────────────────────────
//
class NotificationsScreen extends ConsumerWidget {

  const NotificationsScreen({super.key,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    IconData _iconForType(String type) {
      switch (type) {
        case 'service': return Icons.build_circle_rounded;
        case 'stock': return Icons.inventory_2_rounded;
        case 'payment': return Icons.currency_rupee_rounded;
        default: return Icons.notifications_rounded;
      }
    }

    Color _colorForType(String type) {
      switch (type) {
        case 'service': return kPrimary;
        case 'stock': return kOrange;
        case 'payment': return kGreen;
        default: return kMutedForeground;
      }
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
          onPressed: (){},
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all read', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final n = notifications[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: n.read ? kCard : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: n.read ? kBorder : const Color(0xFFBBCEED), width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _colorForType(n.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForType(n.type), color: _colorForType(n.type), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kForeground)),
                          if (!n.read)
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(n.body, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                      const SizedBox(height: 4),
                      Text(n.time, style: const TextStyle(fontSize: 11, color: kMutedForeground, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16, right: 16, bottom: 24,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: const Icon(Icons.store_rounded, size: 40, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(color: kOrange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Fradeen Auto Works', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Pune, Maharashtra', style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 16, color: i < 4 ? Colors.amber : Colors.white30)),
                      const SizedBox(width: 6),
                      const Text('4.8 (234 reviews)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats
                Row(
                  children: [
                    Expanded(child: _statChip('Total Jobs', '2,841')),
                    const SizedBox(width: 10),
                    Expanded(child: _statChip('Customers', '1,284')),
                    const SizedBox(width: 10),
                    Expanded(child: _statChip('Revenue', '₹12.4L')),
                  ],
                ),
                const SizedBox(height: 20),

                _menuSection('Garage Settings', [
                  _MenuItem(Icons.store_rounded, 'Workshop Info', kPrimary),
                  _MenuItem(Icons.people_rounded, 'Staff & Mechanics', Colors.indigo),
                  _MenuItem(Icons.access_time_rounded, 'Working Hours', Colors.teal),
                  _MenuItem(Icons.receipt_long_rounded, 'Invoice & Tax Settings', Colors.purple),
                ]),
                const SizedBox(height: 14),
                _menuSection('Preferences', [
                  _MenuItem(Icons.notifications_rounded, 'Notifications', kOrange),
                  _MenuItem(Icons.palette_rounded, 'Theme & Display', Colors.pink),
                  _MenuItem(Icons.language_rounded, 'Language', Colors.green),
                  _MenuItem(Icons.backup_rounded, 'Backup & Sync', Colors.cyan),
                ]),
                const SizedBox(height: 14),
                _menuSection('Account', [
                  _MenuItem(Icons.help_rounded, 'Help & Support', Colors.blue),
                  _MenuItem(Icons.shield_rounded, 'Privacy Policy', Colors.grey),
                ]),
                const SizedBox(height: 14),
                GarageCard(
                  onTap: () => AppScreen.splash,
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.logout_rounded, color: kRed, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Logout', style: TextStyle(color: kRed, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder, width: 0.8)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kForeground)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: kMutedForeground, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _menuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder, width: 0.8),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: kMutedForeground, size: 18),
                    onTap: () {},
                  ),
                  if (i < items.length - 1) const Divider(height: 1, indent: 60, color: kBorder),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem(this.icon, this.label, this.color);
}

// ─── Billing / Invoice Screen ─────────────────────────────────────────────────

// class BillingScreen extends ConsumerWidget {
//
//   const BillingScreen({super.key,});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final jobs = ref.watch(jobsProvider);
//
//     return Scaffold(
//       backgroundColor: kBackground,
//       appBar: AppBar(
//         title: const Text('Billing',style: TextStyle(fontWeight: FontWeight.bold),),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
//           onPressed:  (){context.pop();},
//         ),
//         actions: [
//           TextButton.icon(
//             onPressed: () {},
//             icon: const Icon(Icons.filter_list_rounded, size: 16, color: kPrimary),
//             label: const Text('Filter', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
//           ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Summary
//           Row(
//             children: [
//               Expanded(child: _summaryCard('Total Billed', '₹2,45,800', Colors.blue)),
//               const SizedBox(width: 10),
//               Expanded(child: _summaryCard('Pending', '₹11,900', Colors.orange)),
//               const SizedBox(width: 10),
//               Expanded(child: _summaryCard('Collected', '₹2,33,900', Colors.green)),
//             ],
//           ),
//           const SizedBox(height: 16),
//           const Text('Recent Invoices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kForeground)),
//           const SizedBox(height: 10),
//           ...jobs.map((job) => Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: GarageCard(
//               onTap: (){
//                 context.push("/invoice");
//               },
//               child: Row(
//                 children: [
//                   Container(
//                     width: 42, height: 42,
//                     decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
//                     child: const Icon(Icons.receipt_long_rounded, color: kPrimary, size: 22),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(job.id, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPrimary)),
//                         Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kForeground)),
//                         Text(job.date, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(formatCurrency(job.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
//                       const SizedBox(height: 4),
//                       StatusBadge(status: job.status),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           )),
//           const SizedBox(height: 80),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: (){},
//         backgroundColor: kPrimary,
//         icon: const Icon(Icons.add_rounded, color: Colors.white),
//         label: const Text('New Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//     );
//   }
//
//   Widget _summaryCard(String label, String value, MaterialColor color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.w700)),
//           const SizedBox(height: 4),
//           Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color.shade800)),
//         ],
//       ),
//     );
//   }
// }

// ─── Invoice Screen ───────────────────────────────────────────────────────────

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedJobProvider) ?? mockJobs[0];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
          onPressed: (){},
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded, color: kPrimary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.print_rounded, color: kPrimary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download_rounded, color: kPrimary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GarageCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GarageOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPrimary)),
                          const Text('Fradeen Auto Works', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const Text('Pune, Maharashtra 411001', style: TextStyle(fontSize: 11, color: kMutedForeground)),
                          const Text('+91 9876543210', style: TextStyle(fontSize: 11, color: kMutedForeground)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                            child: const Text('PAID', style: TextStyle(color: kGreen, fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                          const SizedBox(height: 4),
                          Text(job.id, style: const TextStyle(fontSize: 11, color: kMutedForeground, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: kBorder),
                  // Bill to
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BILL TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const Text('+91 9876543210', style: TextStyle(fontSize: 12, color: kMutedForeground)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          Text(job.date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Vehicle info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kMuted, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car_rounded, size: 18, color: kPrimary),
                        const SizedBox(width: 8),
                        Text('${job.vehicle} · ${job.brand}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Items
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            color: kMuted,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: Text('Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMutedForeground))),
                              Expanded(child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMutedForeground))),
                              Expanded(child: Text('Rate', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMutedForeground))),
                              Expanded(child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMutedForeground))),
                            ],
                          ),
                        ),
                        ...([
                          ('Engine Oil 10W-40 (1L)', 4, 520, 2080),
                          ('Oil Filter – Universal', 1, 150, 150),
                          ('Air Filter – Maruti Swift', 1, 220, 220),
                          ('Labour - Engine Service', 1, 2500, 2500),
                        ].map((item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder, width: 0.5))),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(item.$1, style: const TextStyle(fontSize: 12))),
                              Expanded(child: Text('${item.$2}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                              Expanded(child: Text('₹${item.$3}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                              Expanded(child: Text('₹${item.$4}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                            ],
                          ),
                        ))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Totals
                  _totalRow('Subtotal', '₹4,950'),
                  const SizedBox(height: 4),
                  _totalRow('GST (18%)', '₹891'),
                  const Divider(height: 16, color: kBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kForeground)),
                      Text(formatCurrency(job.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Invoice'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: kMutedForeground)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}