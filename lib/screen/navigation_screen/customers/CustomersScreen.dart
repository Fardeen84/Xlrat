import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/invoice.dart';
import '../../../providers/billing_providers.dart';
import '../../../providers/jobsProvider.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../widgets/EmptyStateView.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  int _tabIndex = 0;

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w800, color: kForeground)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name *', labelStyle: TextStyle(color: kMutedForeground)),
                  style: TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: mobileController,
                  decoration: InputDecoration(labelText: 'Mobile *', labelStyle: TextStyle(color: kMutedForeground)),
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter mobile' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email (Optional)', labelStyle: TextStyle(color: kMutedForeground)),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'Address (Optional)', labelStyle: TextStyle(color: kMutedForeground)),
                  maxLines: 2,
                  style: TextStyle(color: kForeground),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newCust = BillingCustomer(
                  name: nameController.text.trim(),
                  mobile: mobileController.text.trim(),
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                  createdAt: DateTime.now(),
                );
                await ref.read(customerRepositoryProvider).createCustomer(newCust);
                ref.invalidate(customerListProvider);
                ref.invalidate(filteredBillingCustomersProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredBillingCustomersProvider);
    final selectedCust = ref.watch(selectedCustomerProvider);

    return Scaffold(
      backgroundColor: kBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPC = constraints.maxWidth > 850;
          return filteredAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: kRed))),
            data: (customers) {
              if (isPC) {
                return _buildPCLayout(context, customers, selectedCust);
              } else {
                return _buildMobileLayout(context, customers);
              }
            },
          );
        },
      ),
      floatingActionButton: MediaQuery.of(context).size.width <= 850
          ? FloatingActionButton(
              onPressed: () => _showAddCustomerDialog(context),
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.person_add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  // ── PC Master-Detail Layout ──────────────────────────────────────────────────
  Widget _buildPCLayout(BuildContext context, List<BillingCustomer> customers, BillingCustomer? selectedCust) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column (Master List)
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: kBorder, width: 0.8)),
            ),
            child: Column(
              children: [
                // Header (Title & Add Customer Button)
                Container(
                  color: kCard,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.customersTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
                          ElevatedButton.icon(
                            onPressed: () => _showAddCustomerDialog(context),
                            icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                            label: Text(AppLocalizations.of(context)!.customersAdd, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GarageSearchBar(
                        hint: AppLocalizations.of(context)!.customersSearchHint,
                        onChanged: (v) => ref.read(customerSearchProvider.notifier).state = v,
                      ),
                    ],
                  ),
                ),
                // Scrollable List
                Expanded(
                  child: customers.isEmpty
                      ? EmptyStateView(
                          icon: Icons.people_outline_rounded,
                          title: 'No Customers Found',
                          description: 'Add customer records to view billing histories and vehicles.',
                          ctaLabel: 'Add Customer',
                          onCtaPressed: () => _showAddCustomerDialog(context),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: customers.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${customers.length} customers',
                              style: TextStyle(fontSize: 12, color: kMutedForeground, fontWeight: FontWeight.w600)),
                        );
                      }
                      final customer = customers[i - 1];
                      final isSelected = selectedCust?.id == customer.id;
                      return _CustomerCard(
                        customer: customer,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedCustomerProvider.notifier).state = customer;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Column (Detail View)
        Expanded(
          flex: 6,
          child: Container(
            color: kBackground,
            child: selectedCust == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 64, color: kMutedForeground),
                        SizedBox(height: 12),
                        Text(
                          'Select a customer to view details',
                          style: TextStyle(color: kMutedForeground, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : _buildPCDetailView(context, selectedCust),
          ),
        ),
      ],
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, List<BillingCustomer> filtered) {
    return Column(
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
                  Text(AppLocalizations.of(context)!.customersTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
                  GestureDetector(
                    onTap: () => _showAddCustomerDialog(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GarageSearchBar(
                hint: AppLocalizations.of(context)!.customersSearchHint,
                onChanged: (v) => ref.read(customerSearchProvider.notifier).state = v,
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? EmptyStateView(
                  icon: Icons.people_outline_rounded,
                  title: 'No Customers Found',
                  description: 'Add customer records to view billing histories and vehicles.',
                  ctaLabel: 'Add Customer',
                  onCtaPressed: () => _showAddCustomerDialog(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${filtered.length} customers',
                      style: TextStyle(fontSize: 12, color: kMutedForeground, fontWeight: FontWeight.w600)),
                );
              }
              final customer = filtered[i - 1];
              return _CustomerCard(
                customer: customer,
                onTap: () {
                  ref.read(selectedCustomerProvider.notifier).state = customer;
                  context.push('/customer-detail/${customer.id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── PC Detail View Pane ─────────────────────────────────────────────────────
  Widget _buildPCDetailView(BuildContext context, BillingCustomer customer) {
    final invoicesAsync = ref.watch(invoicesByCustomerProvider(customer.id!));
    final invoices = invoicesAsync.value ?? [];

    final totalSpent = invoices.fold<double>(0, (sum, i) => sum + i.grandTotal).round();
    final pending = invoices.where((i) => i.paymentStatus != PaymentStatus.paid).fold<double>(0, (sum, i) => sum + i.grandTotal).round();

    final vehiclesAsync = ref.watch(vehiclesForCustomerProvider(customer.id!));
    final vehiclesList = vehiclesAsync.value ?? [];

    final initials = customer.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
    final avatar = initials.isNotEmpty ? initials : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(avatar, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(customer.mobile, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _whiteChip('${vehiclesList.length} Vehicles'),
                              const SizedBox(width: 6),
                              _whiteChip('Since ${DateFormat('yyyy').format(customer.createdAt)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _miniStat('Total Spent', formatCurrency(totalSpent))),
                    const SizedBox(width: 12),
                    Expanded(child: _miniStat('Pending', pending > 0 ? formatCurrency(pending) : '—')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/new-job'),
                  icon: const Icon(Icons.assignment_rounded, size: 16, color: Colors.white),
                  label: const Text('New Job Card', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/billing'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16, color: kPrimary),
                  label: const Text('Invoice', style: TextStyle(color: kPrimary)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: kPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                child: Icon(Icons.chat_rounded, color: kForeground, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 20),
          GarageTabBar(
            tabs: [
              AppLocalizations.of(context)!.tabVehicles,
              AppLocalizations.of(context)!.tabInvoices,
              AppLocalizations.of(context)!.tabHistory
            ],
            selectedIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),

          const SizedBox(height: 16),
          if (_tabIndex == 0) ...vehiclesList.map((v) => Padding(
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
                            Text('${v.vehicleBrand} ${v.vehicleModel}'.trim().isNotEmpty ? '${v.vehicleBrand} ${v.vehicleModel}' : 'Unknown Vehicle', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            Text(v.fuelType.isNotEmpty ? v.fuelType : 'Petrol', style: TextStyle(fontSize: 11, color: kMutedForeground)),
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
          )),

          if (_tabIndex == 1)
            ref.watch(jobsProvider).when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Error loading jobs: $err', style: const TextStyle(color: kRed))),
              ),
              data: (allJobs) {
                final filteredJobs = allJobs
                    .where((job) => job.customer.toLowerCase().trim() == customer.name.toLowerCase().trim())
                    .toList();

                if (filteredJobs.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No jobs found for this customer.',
                        style: TextStyle(color: kMutedForeground, fontSize: 13),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredJobs.map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GarageCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.jobNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${job.date} · ${job.brand}', style: TextStyle(fontSize: 11, color: kMutedForeground)),
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
                  )).toList(),
                );
              },
            ),

          if (_tabIndex == 2)
            ...List.generate(invoices.length, (i) {
              final inv = invoices[i];
              final dateStr = DateFormat('dd MMM yyyy').format(inv.invoiceDate);
              final desc = inv.items.map((it) => it.itemName).join(', ');
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
                      if (i < invoices.length - 1) Container(width: 2, height: 40, color: kBorder),
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
                            Text(dateStr, style: TextStyle(fontSize: 11, color: kMutedForeground)),
                            const SizedBox(height: 2),
                            Text(desc.isNotEmpty ? desc : 'Service Invoice', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(formatCurrency(inv.grandTotal.round()), style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
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

class _CustomerCard extends ConsumerWidget {
  final BillingCustomer customer;
  final VoidCallback onTap;
  final bool isSelected;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = customer.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
    final avatar = initials.isNotEmpty ? initials : '?';

    final vehiclesAsync = ref.watch(vehiclesForCustomerProvider(customer.id!));
    final vehiclesCount = vehiclesAsync.value?.length ?? 0;

    final invoicesAsync = ref.watch(invoicesByCustomerProvider(customer.id!));
    final invoices = invoicesAsync.value ?? [];
    final pending = invoices.where((i) => i.paymentStatus != PaymentStatus.paid).fold<double>(0, (sum, i) => sum + i.grandTotal).round();

    final dateStr = DateFormat('dd MMM yyyy').format(customer.createdAt);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? kPrimary : Colors.transparent,
          width: 2,
        ),
      ),
      child: GarageCard(
        onTap: onTap,
        color: isSelected ? kPrimary.withOpacity(0.05) : kCard,
        child: Row(
          children: [
            AvatarWidget(initials: avatar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 11, color: kMutedForeground),
                      const SizedBox(width: 3),
                      Text(customer.mobile, style: TextStyle(fontSize: 12, color: kMutedForeground)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_car_rounded, size: 11, color: kMutedForeground),
                      const SizedBox(width: 3),
                      Text('$vehiclesCount vehicle${vehiclesCount != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 11, color: kMutedForeground)),
                      Text(' · ', style: TextStyle(color: kMutedForeground, fontSize: 11)),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: kMutedForeground)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                    child: Text('₹${(pending / 1000).toStringAsFixed(1)}k due',
                        style: const TextStyle(color: kRed, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded, color: kMutedForeground, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}