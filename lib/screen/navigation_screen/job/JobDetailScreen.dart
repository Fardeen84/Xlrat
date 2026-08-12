import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../models/job.dart';
import '../../../providers/jobsProvider.dart';
import '../../../providers/billing_providers.dart';
import '../../../models/billing_model/InvoiceItem.dart';
import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../providers/mechanicsProvider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  void _showEditJobDialog(BuildContext context, Job job) {
    final complaintCtrl = TextEditingController(text: job.complaint);
    final amountCtrl = TextEditingController(text: job.amount.toString());
    List<String> selectedMechanics = List<String>.from(job.mechanics);
    String selectedStatus = job.status;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final mechanicsAsync = ref.watch(mechanicListProvider);
          bool isSaving = false;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              final List<String> availableMechanics = mechanicsAsync.maybeWhen(
                data: (list) => list.map((m) => m.name).toList(),
                orElse: () => ['Suresh K.', 'Ramesh V.', 'Kiran M.'],
              );

              for (final name in selectedMechanics) {
                if (!availableMechanics.contains(name)) {
                  availableMechanics.add(name);
                }
              }

              return AlertDialog(
                backgroundColor: kCard,
                title: Text(
                  'Edit Job Card',
                  style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: complaintCtrl,
                          decoration: InputDecoration(
                            labelText: 'Complaint Description',
                            labelStyle: TextStyle(color: kMutedForeground),
                          ),
                          maxLines: 3,
                          style: TextStyle(color: kForeground),
                        ),
                        SizedBox(height: 8),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Assign Mechanics',
                            style: TextStyle(
                              fontSize: 12,
                              color: kMutedForeground,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableMechanics.map((name) {
                              final isSelected = selectedMechanics.contains(name);
                              return GestureDetector(
                                onTap: isSaving
                                    ? null
                                    : () {
                                        setStateDialog(() {
                                          if (isSelected) {
                                            selectedMechanics.remove(name);
                                          } else {
                                            selectedMechanics.add(name);
                                          }
                                        });
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimary.withOpacity(0.1)
                                        : kMuted.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? kPrimary : kBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected ? kPrimary : kForeground,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.check_rounded,
                                          color: kPrimary,
                                          size: 14,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle: TextStyle(color: kMutedForeground),
                          ),
                          dropdownColor: kCard,
                          items: [
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text(
                                'Pending',
                                style: TextStyle(color: kForeground),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'in-progress',
                              child: Text(
                                'In Progress',
                                style: TextStyle(color: kForeground),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text(
                                'Completed',
                                style: TextStyle(color: kForeground),
                              ),
                            ),
                          ],
                          onChanged: isSaving ? null : (v) {
                            if (v != null) setStateDialog(() => selectedStatus = v);
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: amountCtrl,
                          decoration: InputDecoration(
                            labelText: 'Estimate Amount',
                            labelStyle: TextStyle(color: kMutedForeground),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: kForeground),
                          validator: (value) =>
                          (value == null || int.tryParse(value) == null)
                              ? 'Please enter a valid amount'
                              : null,
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
                              setStateDialog(() {
                                isSaving = true;
                              });
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                final updatedJob = job.copyWith(
                                  complaint: complaintCtrl.text.trim(),
                                  mechanics: selectedMechanics,
                                  status: selectedStatus,
                                  amount: int.parse(amountCtrl.text.trim()),
                                );
                                await ref.read(jobRepositoryProvider).updateJob(updatedJob);
                                ref.invalidate(jobByIdProvider(job.id!));
                                ref.invalidate(jobsListStateProvider);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Job Card updated successfully')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Failed to update Job Card: $e')),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setStateDialog(() {
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
      ),
    );
  }

  void _showDeleteJobConfirmationDialog(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCard,
        title: Text(
          'Delete Job Card',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Text(
          'Are you sure you want to delete Job Card ${job.jobNumber}? This action cannot be undone.',
          style: TextStyle(color: kForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRed),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final router = GoRouter.of(context);
                await ref
                    .read(jobRepositoryProvider)
                    .deleteJob(job.id!);
                ref.invalidate(jobsListStateProvider);
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  router.go('/jobs');
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Job Card deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete Job Card: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateInvoice(BuildContext context, Job job) async {
    final notifier = ref.read(invoiceDraftProvider.notifier);
    notifier.reset();

    BillingCustomer? customer;
    if (job.customerId != null) {
      try {
        customer = await ref.read(customerRepositoryProvider).getCustomer(job.customerId!);
      } catch (e) {
        print('Error resolving customer by ID: $e');
      }
    }
    if (customer == null && job.customer.isNotEmpty && job.customer != 'Unknown') {
      try {
        final customers = await ref.read(customerRepositoryProvider).searchCustomers(job.customer);
        if (customers.isNotEmpty) {
          customer = customers.firstWhere(
                (c) => c.name.toLowerCase() == job.customer.toLowerCase(),
            orElse: () => customers.first,
          );
        }
      } catch (e) {
        print('Error searching customer by name: $e');
      }
    }

    BillingVehicle? vehicle;
    if (job.vehicleId != null) {
      try {
        vehicle = await ref.read(vehicleRepositoryProvider).getVehicle(job.vehicleId!);
      } catch (e) {
        print('Error resolving vehicle by ID: $e');
      }
    }
    if (vehicle == null && job.vehicle.isNotEmpty && job.vehicle != 'Unknown') {
      try {
        final vehicles = await ref.read(vehicleRepositoryProvider).searchVehicles(job.vehicle);
        if (vehicles.isNotEmpty) {
          vehicle = vehicles.firstWhere(
                (v) => v.vehicleNumber.toUpperCase() == job.vehicle.toUpperCase(),
            orElse: () => vehicles.first,
          );
        }
      } catch (e) {
        print('Error searching vehicle by number: $e');
      }
    }

    if (customer != null) {
      notifier.setCustomer(customer);
    }
    if (vehicle != null) {
      notifier.setVehicle(vehicle);
    }

    if (job.amount > 0 || job.complaint.isNotEmpty) {
      notifier.addItem(InvoiceItem(
        itemName: job.complaint.isNotEmpty ? job.complaint : 'Service/Labor Charge',
        quantity: 1.0,
        price: job.amount.toDouble(),
        total: job.amount.toDouble(),
        createdAt: DateTime.now(),
      ));
    }

    if (context.mounted) {
      context.go('/billing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobByIdProvider(widget.jobId));

    return jobAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (job) {
        if (job == null) {
          return const Scaffold(body: Center(child: Text('Job not found')));
        }
        return _buildJobDetailContent(context, job);
      },
    );
  }

  Widget _buildJobDetailContent(BuildContext context, Job job) {
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
                  icon: Icon(Icons.arrow_back_rounded, color: kForeground),
                  onPressed: () => context.go('/jobs'),
                ),
                Expanded(
                  child: Text(
                    job.jobNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kForeground,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: kForeground),
                  color: kCard,
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditJobDialog(context, job);
                    } else if (val == 'delete') {
                      _showDeleteJobConfirmationDialog(context, job);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit Job Card',
                        style: TextStyle(color: kForeground),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Job Card',
                        style: TextStyle(color: kRed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                StatusBadge(status: job.status),
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
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                job.jobType == 'item'
                                    ? Icons.inventory_2_rounded
                                    : (job.vehicleType == 'bike'
                                    ? Icons.motorcycle_rounded
                                    : Icons.directions_car_rounded),
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.jobType == 'item' ? 'Item' : 'Vehicle',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    job.jobType == 'item' ? job.itemName : job.vehicle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (job.jobType == 'item')
                                    if (job.itemDescription.isNotEmpty)
                                      Text(
                                        job.itemDescription,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      )
                                    else
                                      const SizedBox()
                                  else
                                    Text(
                                      job.brand,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _infoChip('Mechanics', job.mechanics.isNotEmpty ? job.mechanics.join(', ') : 'Unassigned'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _infoChip(
                                'Date',
                                job.date.split(' ').take(2).join(' '),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _infoChip(
                                'Amount',
                                formatCurrency(job.amount),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  GarageCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOMER COMPLAINT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: kMutedForeground,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          job.complaint.isNotEmpty
                              ? job.complaint
                              : 'No complaint description provided.',
                          style: TextStyle(
                            fontSize: 14,
                            color: kForeground,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  GarageCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JOB DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: kMutedForeground,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Mechanics Assigned',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (job.mechanics.isEmpty)
                              const Text(
                                'Unassigned',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Expanded(
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: job.mechanics.map((name) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: kMuted.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kForeground,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(fontSize: 13),
                            ),
                            StatusBadge(status: job.status),
                          ],
                        ),
                        Divider(color: kBorder),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Estimate',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              formatCurrency(job.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (job.status != 'completed')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(jobRepositoryProvider)
                                  .updateJobStatus(job.id!, 'completed');
                              ref.invalidate(jobsListStateProvider);
                              ref.invalidate(jobByIdProvider(job.id!));
                            },
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Mark Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (job.status != 'completed') const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generateInvoice(context, job),
                          icon: const Icon(
                            Icons.receipt_long_rounded,
                            size: 16,
                          ),
                          label: const Text('Generate Bill'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateInvoice(context, job),
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: const Text('Generate Invoice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    final text = job.jobType == 'item'
                        ? 'Job Card Details:\n'
                        'Job Number: ${job.jobNumber}\n'
                        'Customer: ${job.customer}\n'
                        'Item: ${job.itemName}\n'
                        'Description: ${job.itemDescription}\n'
                        'Complaint: ${job.complaint}\n'
                        'Status: ${job.status}\n'
                        'Amount: ${formatCurrency(job.amount)}'
                        : 'Job Card Details:\n'
                        'Job Number: ${job.jobNumber}\n'
                        'Customer: ${job.customer}\n'
                        'Vehicle: ${job.vehicle} (${job.brand})\n'
                        'Complaint: ${job.complaint}\n'
                        'Status: ${job.status}\n'
                        'Amount: ${formatCurrency(job.amount)}';
                    SharePlus.instance.share(ShareParams(text: text));
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.share_rounded,
                      color: kForeground,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
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
        Text(label, style: TextStyle(color: Colors.white, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}