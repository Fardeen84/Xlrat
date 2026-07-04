import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../models/billing_model/InvoiceItem.dart';
import '../../../models/billing_model/invoice.dart';
import '../../../providers/billing_providers.dart';
import '../../../widgets/EmptyStateView.dart';

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

  void _showEditCustomerDialog(BuildContext context, BillingCustomer customer) {
    final nameController = TextEditingController(text: customer.name);
    final mobileController = TextEditingController(text: customer.mobile);
    final emailController = TextEditingController(text: customer.email);
    final addressController = TextEditingController(text: customer.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Edit Customer', style: TextStyle(fontWeight: FontWeight.w800, color: kForeground)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile *', labelStyle: TextStyle(color: kMutedForeground)),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter mobile' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email (Optional)', labelStyle: TextStyle(color: kMutedForeground)),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address (Optional)', labelStyle: TextStyle(color: kMutedForeground)),
                  maxLines: 2,
                  style: const TextStyle(color: kForeground),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updated = customer.copyWith(
                  name: nameController.text.trim(),
                  mobile: mobileController.text.trim(),
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                );
                await ref.read(customerRepositoryProvider).updateCustomer(updated);
                ref.invalidate(customerByIdProvider(widget.customerId));
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

  void _showDeleteConfirmationDialog(BuildContext context, BillingCustomer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Delete Customer', style: TextStyle(fontWeight: FontWeight.w800, color: kForeground)),
        content: Text('Are you sure you want to delete ${customer.name}? This will also delete all their vehicles and invoices.', style: const TextStyle(color: kForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () async {
              final router = GoRouter.of(context);
              await ref.read(customerRepositoryProvider).deleteCustomer(customer.id!);
              ref.invalidate(customerListProvider);
              ref.invalidate(filteredBillingCustomersProvider);
              if (context.mounted) {
                Navigator.pop(context);
                router.go('/customers');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final numberCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final fuelTypeCtrl = TextEditingController();
    final engineNumberCtrl = TextEditingController();
    final chassisNumberCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.w800, color: kForeground)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Vehicle Number *', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter vehicle number' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(labelText: 'Brand', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: 'Model', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: fuelTypeCtrl,
                  decoration: const InputDecoration(labelText: 'Fuel Type', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: engineNumberCtrl,
                  decoration: const InputDecoration(labelText: 'Engine Number', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: chassisNumberCtrl,
                  decoration: const InputDecoration(labelText: 'Chassis Number', labelStyle: TextStyle(color: kMutedForeground)),
                  style: const TextStyle(color: kForeground),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newVehicle = BillingVehicle(
                  customerId: widget.customerId,
                  vehicleNumber: numberCtrl.text.trim().toUpperCase(),
                  vehicleBrand: brandCtrl.text.trim(),
                  vehicleModel: modelCtrl.text.trim(),
                  fuelType: fuelTypeCtrl.text.trim(),
                  engineNumber: engineNumberCtrl.text.trim(),
                  chassisNumber: chassisNumberCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                await ref.read(vehicleRepositoryProvider).createVehicle(newVehicle);
                ref.invalidate(vehiclesForCustomerProvider(widget.customerId));
                ref.invalidate(allVehiclesProvider);
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
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));

    final invoicesAsync = ref.watch(invoicesByCustomerProvider(widget.customerId));
    final invoices = invoicesAsync.value ?? [];

    final vehiclesAsync = ref.watch(vehiclesForCustomerProvider(widget.customerId));
    final vehiclesList = vehiclesAsync.value ?? [];

    final uniqueVehiclesCount = vehiclesList.length;
    final totalSpent = invoices.fold<double>(0, (sum, i) => sum + i.grandTotal).round();
    final pending = invoices.where((i) => i.paymentStatus != PaymentStatus.paid).fold<double>(0, (sum, i) => sum + i.grandTotal).round();

    return Scaffold(
      backgroundColor: kBackground,
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: kRed))),
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found', style: TextStyle(color: kMutedForeground)));
          }

          final initials = customer.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
          final avatar = initials.isNotEmpty ? initials : '?';

          return CustomScrollView(
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: kForeground),
                    color: kCard,
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditCustomerDialog(context, customer);
                      } else if (val == 'delete') {
                        _showDeleteConfirmationDialog(context, customer);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Customer', style: TextStyle(color: kForeground))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Customer', style: TextStyle(color: kForeground))),
                    ],
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
                                      avatar,
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
                                        Text(customer.mobile,
                                            style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                                      ]),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _chip('$uniqueVehiclesCount Vehicle${uniqueVehiclesCount == 1 ? '' : 's'}'),
                                          const SizedBox(width: 8),
                                          _chip('Since ${DateFormat('yyyy').format(customer.createdAt)}'),
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
                              onPressed: () {
                                ref.read(selectedCustomerProvider.notifier).state = customer;
                                context.go('/new-job');
                              },
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
                              onPressed: () {
                                ref.read(selectedCustomerProvider.notifier).state = customer;
                                context.go('/billing');
                              },
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

                      if (_tabIndex == 0) ...[
                        ElevatedButton.icon(
                          onPressed: () => _showAddVehicleDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Vehicle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (vehiclesList.isEmpty)
                          EmptyStateView(
                            icon: Icons.directions_car_rounded,
                            title: 'No Vehicles Added',
                            description: 'Add vehicles for this customer to map them to invoices and job cards.',
                            ctaLabel: 'Add Vehicle',
                            onCtaPressed: () => _showAddVehicleDialog(context),
                          )
                        else
                          ...vehiclesList.map((v) => Padding(
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
                          )),
                      ],

                      if (_tabIndex == 1)
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
                              return EmptyStateView(
                                icon: Icons.receipt_long_rounded,
                                title: 'No Invoices Created',
                                description: 'Create an invoice to bill this customer for parts and services.',
                                ctaLabel: 'Create Invoice',
                                onCtaPressed: () {
                                  ref.read(selectedCustomerProvider.notifier).state = customer;
                                  context.go('/billing');
                                },
                              );
                            }

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
                          },
                        ),

                      if (_tabIndex == 2)
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
                              return const EmptyStateView(
                                icon: Icons.history_rounded,
                                title: 'No History',
                                description: 'Service timeline history will appear here once invoices are created.',
                              );
                            }
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
                          },
                        ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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