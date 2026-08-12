import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../models/billing_model/invoice.dart';
import '../../../providers/billing_providers.dart';
import '../../../providers/jobsProvider.dart';
import '../../../models/job.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../widgets/EmptyStateView.dart';
import '../../../providers/newJobFormProvider.dart';
import '../../../models/NewJobFormState.dart';

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
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kCard,
              title: Text(
                'Add Customer',
                style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name *',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter name'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: mobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile *',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: kForeground),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter mobile'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Address (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        maxLines: 2,
                        style: TextStyle(color: kForeground),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        isSaving = true;
                      });
                      try {
                        final newCust = BillingCustomer(
                          name: nameController.text.trim(),
                          mobile: mobileController.text.trim(),
                          email: emailController.text.trim(),
                          address: addressController.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await ref
                            .read(customerRepositoryProvider)
                            .createCustomer(newCust);
                        ref.invalidate(customerListStateProvider);
                        ref.invalidate(filteredBillingCustomersProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e is Exception
                                    ? e.toString().replaceAll('Exception: ', '')
                                    : 'Failed to save customer: $e',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScanDuplicatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kCard,
          title: Text(
            'Scan Duplicate Customers',
            style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
          ),
          content: SizedBox(
            width: 450,
            height: 400,
            child: FutureBuilder<List<BillingCustomer>>(
              future: ref.read(customerRepositoryProvider).getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: kRed)));
                }
                final customers = snapshot.data ?? [];

                // Group by mobile number (trimmed)
                final Map<String, List<BillingCustomer>> groups = {};
                for (final c in customers) {
                  final m = c.mobile.trim();
                  if (m.isNotEmpty) {
                    groups.putIfAbsent(m, () => []).add(c);
                  }
                }

                // Filter groups with size > 1
                final duplicateGroups = groups.entries
                    .where((entry) => entry.value.length > 1)
                    .toList();

                if (duplicateGroups.isEmpty) {
                  return Center(
                    child: Text(
                      'No duplicate customers found by mobile number!',
                      style: TextStyle(color: kMutedForeground),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: duplicateGroups.length,
                  itemBuilder: (context, index) {
                    final entry = duplicateGroups[index];
                    final mobile = entry.key;
                    final list = entry.value;
                    return Card(
                      color: kBackground,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mobile: $mobile',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
                            ),
                            const SizedBox(height: 4),
                            ...list.map((c) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(c.name, style: TextStyle(color: kForeground)),
                                subtitle: Text(
                                  'Created: ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}\nID: ${c.id}',
                                  style: TextStyle(color: kMutedForeground, fontSize: 10),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: kRed, size: 18),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: kCard,
                                        title: const Text('Delete Duplicate?'),
                                        content: Text('Are you sure you want to delete "${c.name}"? This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: kRed),
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(customerRepositoryProvider).deleteCustomer(c.id!);
                                      ref.invalidate(customerListStateProvider);
                                      ref.invalidate(filteredBillingCustomersProvider);
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext); // Close the scanner dialog to refresh
                                        _showScanDuplicatesDialog(context); // Re-open scanner
                                      }
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Close', style: TextStyle(color: kMutedForeground)),
            ),
          ],
        );
      },
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
            error: (err, stack) => Center(
              child: Text('Error: $err', style: const TextStyle(color: kRed)),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      )
          : null,
    );
  }

  // ── PC Master-Detail Layout ──────────────────────────────────────────────────
  Widget _buildPCLayout(
      BuildContext context,
      List<BillingCustomer> customers,
      BillingCustomer? selectedCust,
      ) {
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
                          Text(
                            AppLocalizations.of(context)!.customersTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kForeground,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _showScanDuplicatesDialog(context),
                                icon: Icon(Icons.cleaning_services_rounded, size: 16, color: kMutedForeground),
                                label: Text('Clean Duplicates', style: TextStyle(color: kMutedForeground, fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showAddCustomerDialog(context),
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: Text(
                                  AppLocalizations.of(context)!.customersAdd,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GarageSearchBar(
                        hint: AppLocalizations.of(context)!.customersSearchHint,
                        onChanged: (v) =>
                        ref.read(customerSearchProvider.notifier).state = v,
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
                    description:
                    'Add customer records to view billing histories and vehicles.',
                    ctaLabel: 'Add Customer',
                    onCtaPressed: () => _showAddCustomerDialog(context),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: customers.length + 1 + (ref.watch(customerListStateProvider).hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${customers.length} customers',
                            style: TextStyle(
                              fontSize: 12,
                              color: kMutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      if (i == customers.length + 1) {
                        return const _LoadMoreCustomersButton();
                      }
                      final customer = customers[i - 1];
                      final isSelected = selectedCust?.id == customer.id;
                      return _CustomerCard(
                        customer: customer,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedCustomerProvider.notifier)
                              .state =
                              customer;
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
                  Icon(
                    Icons.person_outline_rounded,
                    size: 64,
                    color: kMutedForeground,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Select a customer to view details',
                    style: TextStyle(
                      color: kMutedForeground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
  Widget _buildMobileLayout(
      BuildContext context,
      List<BillingCustomer> filtered,
      ) {
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
                  Text(
                    AppLocalizations.of(context)!.customersTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kForeground,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.cleaning_services_rounded, color: kMutedForeground, size: 20),
                        onPressed: () => _showScanDuplicatesDialog(context),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showAddCustomerDialog(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GarageSearchBar(
                hint: AppLocalizations.of(context)!.customersSearchHint,
                onChanged: (v) =>
                ref.read(customerSearchProvider.notifier).state = v,
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? EmptyStateView(
            icon: Icons.people_outline_rounded,
            title: 'No Customers Found',
            description:
            'Add customer records to view billing histories and vehicles.',
            ctaLabel: 'Add Customer',
            onCtaPressed: () => _showAddCustomerDialog(context),
          )
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: filtered.length + 1 + (ref.watch(customerListStateProvider).hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${filtered.length} customers',
                    style: TextStyle(
                      fontSize: 12,
                      color: kMutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              if (i == filtered.length + 1) {
                return const _LoadMoreCustomersButton();
              }
              final customer = filtered[i - 1];
              return _CustomerCard(
                customer: customer,
                onTap: () {
                  ref.read(selectedCustomerProvider.notifier).state =
                      customer;
                  context.push('/customer-detail/${customer.id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Vehicle edit/delete (ported from CustomerDetailScreen.dart — this
  // desktop split-view previously only displayed vehicles read-only) ──────
  void _showEditVehicleDialog(BuildContext context, BillingVehicle vehicle) {
    final numberCtrl = TextEditingController(text: vehicle.vehicleNumber);
    final brandCtrl = TextEditingController(text: vehicle.vehicleBrand);
    final modelCtrl = TextEditingController(text: vehicle.vehicleModel);
    final fuelTypeCtrl = TextEditingController(text: vehicle.fuelType);
    final engineNumberCtrl = TextEditingController(text: vehicle.engineNumber);
    final chassisNumberCtrl = TextEditingController(text: vehicle.chassisNumber);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kCard,
              title: Text(
                'Edit Vehicle',
                style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: numberCtrl,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Number *',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter vehicle number'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: brandCtrl,
                        decoration: InputDecoration(
                          labelText: 'Brand',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: modelCtrl,
                        decoration: InputDecoration(
                          labelText: 'Model',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: fuelTypeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Fuel Type',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: engineNumberCtrl,
                        decoration: InputDecoration(
                          labelText: 'Engine Number',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: chassisNumberCtrl,
                        decoration: InputDecoration(
                          labelText: 'Chassis Number',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        isSaving = true;
                      });
                      try {
                        final updatedVehicle = vehicle.copyWith(
                          vehicleNumber: numberCtrl.text.trim().toUpperCase(),
                          vehicleBrand: brandCtrl.text.trim(),
                          vehicleModel: modelCtrl.text.trim(),
                          fuelType: fuelTypeCtrl.text.trim(),
                          engineNumber: engineNumberCtrl.text.trim(),
                          chassisNumber: chassisNumberCtrl.text.trim(),
                        );
                        await ref
                            .read(vehicleRepositoryProvider)
                            .updateVehicle(updatedVehicle);
                        ref.invalidate(vehiclesForCustomerProvider(vehicle.customerId));
                        ref.invalidate(allVehiclesProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehicle updated successfully')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update vehicle: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteVehicleConfirmationDialog(
      BuildContext context,
      BillingVehicle vehicle,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<Job>>(
          future: ref.read(jobRepositoryProvider).getJobsForVehicle(vehicle.id!),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final linkedJobsCount = snapshot.data?.length ?? 0;

            final String message = isLoading
                ? 'Checking linked job cards...'
                : linkedJobsCount > 0
                ? 'This vehicle is linked to $linkedJobsCount job card(s). Deleting it will not delete those job cards, but they will show an orphaned/missing vehicle reference. Are you sure you want to continue?'
                : 'Are you sure you want to delete vehicle ${vehicle.vehicleNumber}? This action cannot be undone and may affect linked job cards and invoices.';

            return AlertDialog(
              backgroundColor: kCard,
              title: Text(
                'Delete Vehicle',
                style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Text(
                    message,
                    style: TextStyle(color: kForeground),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                ),
                if (!isLoading)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: kRed),
                    onPressed: () async {
                      try {
                        await ref
                            .read(vehicleRepositoryProvider)
                            .deleteVehicle(vehicle.id!);
                        ref.invalidate(vehiclesForCustomerProvider(vehicle.customerId));
                        ref.invalidate(allVehiclesProvider);
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehicle deleted successfully')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete vehicle: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ── PC Detail View Pane ─────────────────────────────────────────────────────
  Widget _buildPCDetailView(BuildContext context, BillingCustomer customer) {
    final invoicesAsync = ref.watch(invoicesByCustomerProvider(customer.id!));
    final invoices = invoicesAsync.value ?? [];

    final totalSpent = invoices
        .fold<double>(0, (sum, i) => sum + i.grandTotal)
        .round();
    final pending = invoices
        .where((i) => i.paymentStatus != PaymentStatus.paid)
        .fold<double>(0, (sum, i) => sum + i.grandTotal)
        .round();

    final vehiclesAsync = ref.watch(vehiclesForCustomerProvider(customer.id!));
    final vehiclesList = vehiclesAsync.value ?? [];

    final initials = customer.name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('')
        .toUpperCase();
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
                colors: [Color(0xFFFDB913), Color(0xFFFDB918)],
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
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.mobile,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _whiteChip('${vehiclesList.length} Vehicles'),
                              const SizedBox(width: 6),
                              _whiteChip(
                                'Since ${DateFormat('yyyy').format(customer.createdAt)}',
                              ),
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
                    Expanded(
                      child: _miniStat(
                        'Total Spent',
                        formatCurrency(totalSpent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniStat(
                        'Pending',
                        pending > 0 ? formatCurrency(pending) : '—',
                      ),
                    ),
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
                  onPressed: () {
                    ref.read(newJobFormProvider.notifier).state =
                        NewJobFormState(
                          step: 2,
                          customer: customer,
                        );
                    context.push('/new-job');
                  },
                  icon: const Icon(
                    Icons.assignment_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'New Job Card',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/billing'),
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: kPrimary,
                  ),
                  label: const Text(
                    'Invoice',
                    style: TextStyle(color: kPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
              AppLocalizations.of(context)!.tabHistory,
            ],
            selectedIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),

          const SizedBox(height: 16),
          if (_tabIndex == 0)
            ...vehiclesList.map(
                  (v) => Padding(
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
                                  '${v.vehicleBrand} ${v.vehicleModel}'
                                      .trim()
                                      .isNotEmpty
                                      ? '${v.vehicleBrand} ${v.vehicleModel}'
                                      : 'Unknown Vehicle',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  v.fuelType.isNotEmpty ? v.fuelType : 'Petrol',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kMutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v.vehicleNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: kMutedForeground, size: 20),
                        color: kCard,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showEditVehicleDialog(context, v);
                          } else if (val == 'delete') {
                            _showDeleteVehicleConfirmationDialog(context, v);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit Vehicle',
                              style: TextStyle(color: kForeground),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete Vehicle',
                              style: TextStyle(color: kRed),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_tabIndex == 1)
            ref
                .watch(jobsProvider)
                .when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Error loading jobs: $err',
                    style: const TextStyle(color: kRed),
                  ),
                ),
              ),
              data: (allJobs) {
                final filteredJobs = allJobs
                    .where(
                      (job) =>
                  job.customer.toLowerCase().trim() ==
                      customer.name.toLowerCase().trim(),
                )
                    .toList();

                if (filteredJobs.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No jobs found for this customer.',
                        style: TextStyle(
                          color: kMutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredJobs
                      .map(
                        (job) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GarageCard(
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.jobNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  job.jobType == 'item'
                                      ? (job.itemDescription.isNotEmpty
                                      ? '${job.date} · ${job.itemName} (${job.itemDescription})'
                                      : '${job.date} · ${job.itemName}')
                                      : '${job.date} · ${job.brand}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kMutedForeground,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatCurrency(job.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(status: job.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .toList(),
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
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: kGreen,
                        ),
                      ),
                      if (i < invoices.length - 1)
                        Container(width: 2, height: 40, color: kBorder),
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
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: kMutedForeground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc.isNotEmpty ? desc : 'Service Invoice',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(inv.grandTotal.round()),
                              style: const TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
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
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
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

  void _showEditCustomerDialog(BuildContext context, WidgetRef ref, BillingCustomer customer) {
    final nameController = TextEditingController(text: customer.name);
    final mobileController = TextEditingController(text: customer.mobile);
    final emailController = TextEditingController(text: customer.email);
    final addressController = TextEditingController(text: customer.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kCard,
              title: Text(
                'Edit Customer',
                style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name *',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        style: TextStyle(color: kForeground),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter name'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: mobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile *',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: kForeground),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter mobile'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Address (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        maxLines: 2,
                        style: TextStyle(color: kForeground),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        isSaving = true;
                      });
                      try {
                        final updated = customer.copyWith(
                          name: nameController.text.trim(),
                          mobile: mobileController.text.trim(),
                          email: emailController.text.trim(),
                          address: addressController.text.trim(),
                        );
                        await ref
                            .read(customerRepositoryProvider)
                            .updateCustomer(updated);
                        ref.invalidate(customerListStateProvider);
                        ref.invalidate(filteredBillingCustomersProvider);
                        ref.invalidate(customerByIdProvider(customer.id!));
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update customer: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = customer.name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('')
        .toUpperCase();
    final avatar = initials.isNotEmpty ? initials : '?';

    final vehiclesAsync = ref.watch(vehiclesForCustomerProvider(customer.id!));
    final vehiclesCount = vehiclesAsync.value?.length ?? 0;

    final invoicesAsync = ref.watch(invoicesByCustomerProvider(customer.id!));
    final invoices = invoicesAsync.value ?? [];
    final pending = invoices
        .where((i) => i.paymentStatus != PaymentStatus.paid)
        .fold<double>(0, (sum, i) => sum + i.grandTotal)
        .round();

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
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: kForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 11,
                        color: kMutedForeground,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        customer.mobile,
                        style: TextStyle(fontSize: 12, color: kMutedForeground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 11,
                        color: kMutedForeground,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$vehiclesCount vehicle${vehiclesCount != 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 11, color: kMutedForeground),
                      ),
                      Text(
                        ' · ',
                        style: TextStyle(color: kMutedForeground, fontSize: 11),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11, color: kMutedForeground),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_rounded, color: kMutedForeground, size: 20),
              onPressed: () => _showEditCustomerDialog(context, ref, customer),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${(pending / 1000).toStringAsFixed(1)}k due',
                      style: const TextStyle(
                        color: kRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: kMutedForeground,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreCustomersButton extends ConsumerWidget {
  const _LoadMoreCustomersButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerListStateProvider);
    if (!state.hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: state.isLoadMore
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () => ref.read(customerListStateProvider.notifier).loadMore(),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Load More'),
        ),
      ),
    );
  }
}