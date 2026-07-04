import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/job.dart';
import '../../../providers/jobsProvider.dart';
import '../../../providers/billing_providers.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../widgets/EmptyStateView.dart';


class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  // Reusing the call mechanism from InvoiceHistoryScreen.dart
  // Note: Phone numbers will show mock/fake values until providers are database-backed.
  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      final Uri url = Uri(scheme: 'tel', path: phoneNumber);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      } catch (e) {
        debugPrint('Could not launch call url: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(jobFilterProvider);
    final filtered = ref.watch(filteredJobsProvider);
    final allJobsAsync = ref.watch(jobsProvider);
    final allJobs = allJobsAsync.value ?? [];
    final customers = ref.watch(customerListProvider).value ?? [];

    final counts = {
      'all': allJobs.length,
      'pending': allJobs.where((j) => j.status == 'pending').length,
      'in-progress': allJobs.where((j) => j.status == 'in-progress').length,
      'completed': allJobs.where((j) => j.status == 'completed').length,
    };

    final l10n = AppLocalizations.of(context)!;
    final filters = [
      ('all', '${l10n.jobsFilterAll} (${counts['all']})'),
      ('pending', '${l10n.statusPending} (${counts['pending']})'),
      ('in-progress', '${l10n.statusInProgress} (${counts['in-progress']})'),
      ('completed', '${l10n.statusCompleted} (${counts['completed']})'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPC = constraints.maxWidth > 900;
        if (isPC) {
          return _buildPCLayout(context, ref, filtered, filters, filter, customers);
        } else {
          return _buildMobileLayout(context, ref, filtered, filters, filter, customers);
        }
      },
    );
  }

  // ── PC Mode Layout (Data Table View) ───────────────────────────────────────
  Widget _buildPCLayout(
    BuildContext context,
    WidgetRef ref,
    List<Job> filteredJobs,
    List<(String, String)> filters,
    String activeFilter,
    List<BillingCustomer> customers,
  ) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PC Header
          Container(
            color: kCard,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.jobsTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kForeground),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push("/new-job"),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  label: Text(AppLocalizations.of(context)!.jobsNewJobCard, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Filters row
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: filters.map((f) {
                      final isActive = activeFilter == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          onTap: () => ref.read(jobFilterProvider.notifier).state = f.$1,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? kCard : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Text(
                              f.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? kPrimary : kMutedForeground,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: filteredJobs.isEmpty
                ? EmptyStateView(
                    icon: Icons.assignment_outlined,
                    title: 'No Job Cards Found',
                    description: 'Create a new job card to track service work, assigned mechanics, and vehicle status.',
                    ctaLabel: 'New Job Card',
                    onCtaPressed: () => context.push('/new-job'),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder, width: 0.8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: kBorder,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(kMuted.withValues(alpha: 0.4)),
                              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: kForeground),
                              columns: [
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColJobId)),
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColCustomer)),
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColVehicle)),
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColComplaint)),
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColMechanic)),
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColAmount)),
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColStatus)),
                                DataColumn(label: Text(AppLocalizations.of(context)!.jobsColActions)),
                              ],
                              rows: filteredJobs.map((job) {
                                final customer = customers.firstWhere(
                                  (c) => c.name.trim().toLowerCase() == job.customer.trim().toLowerCase(),
                                  orElse: () => BillingCustomer(
                                    id: 0,
                                    name: '',
                                    mobile: '',
                                    createdAt: DateTime.now(),
                                  ),
                                );
                                final phone = customer.mobile;
                                final initials = customer.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
                                final avatar = initials.isNotEmpty ? initials : '?';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        job.jobNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kPrimary,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: kPrimary.withValues(alpha: 0.1),
                                            child: Text(
                                              avatar,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: kPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.phone_rounded, color: kGreen, size: 16),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _makeCall(phone),
                                              tooltip: 'Call Customer $phone',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    DataCell(Text('${job.vehicle} (${job.brand})')),
                                    DataCell(
                                      SizedBox(
                                        width: 200,
                                        child: Text(
                                          job.complaint,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(job.mechanic)),
                                    DataCell(Text(formatCurrency(job.amount))),
                                    DataCell(StatusBadge(status: job.status)),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_rounded, color: kPrimary, size: 18),
                                        onPressed: () {
                                          ref.read(selectedJobProvider.notifier).state = job;
                                          context.push('/job-detail/${job.id}');
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Mode Layout ─────────────────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    List<Job> filteredJobs,
    List<(String, String)> filters,
    String activeFilter,
    List<BillingCustomer> customers,
  ) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
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
                    Text(AppLocalizations.of(context)!.jobsTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
                    GestureDetector(
                      onTap: () {
                        context.push("/new-job");
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: filters.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: f.$2,
                          selected: activeFilter == f.$1,
                          onTap: () => ref.read(jobFilterProvider.notifier).state = f.$1,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredJobs.isEmpty
                ? EmptyStateView(
                    icon: Icons.assignment_outlined,
                    title: 'No Job Cards Found',
                    description: 'Create a new job card to track service work, assigned mechanics, and vehicle status.',
                    ctaLabel: 'New Job Card',
                    onCtaPressed: () => context.push('/new-job'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: filteredJobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final job = filteredJobs[i];
                 final customer = customers.firstWhere(
                   (c) => c.name.trim().toLowerCase() == job.customer.trim().toLowerCase(),
                   orElse: () => BillingCustomer(
                     id: 0,
                     name: '',
                     mobile: '',
                     createdAt: DateTime.now(),
                   ),
                 );
                 return _JobCard(
                   job: job,
                   customerPhone: customer.mobile,
                  onTap: () {
                    ref.read(selectedJobProvider.notifier).state = job;
                    context.push('/job-detail/${job.id}');
                  },
                  onCall: _makeCall,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push("/new-job");
        },
        backgroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final String? customerPhone;
  final VoidCallback onTap;
  final Future<void> Function(String) onCall;

  const _JobCard({
    required this.job,
    required this.customerPhone,
    required this.onTap,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return GarageCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VehicleIcon(type: job.vehicleType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.jobNumber,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  job.customer,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 14, color: kForeground),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (customerPhone != null && customerPhone!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.phone_rounded, color: kGreen, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => onCall(customerPhone!),
                                  tooltip: 'Call Customer $customerPhone',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${job.vehicle} · ${job.brand}', style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                const SizedBox(height: 2),
                Text(job.complaint,
                    style: const TextStyle(fontSize: 12, color: kMutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration:
                              BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(11)),
                          child: const Icon(Icons.build_rounded, size: 12, color: kPrimary),
                        ),
                        const SizedBox(width: 6),
                        Text(job.mechanic, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                      ],
                    ),
                    Text(formatCurrency(job.amount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kForeground)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}