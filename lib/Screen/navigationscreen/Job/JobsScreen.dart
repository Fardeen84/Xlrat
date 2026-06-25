// lib/screens/jobs_screen.dart
import 'package:flutter/material.dart' hide FilterChip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../Models/CustomerModelas.dart';
import '../../../Models/NewJobFormState.dart';
import '../../../Models/job.dart';
import '../../../Providers/NavigationProvider.dart';
import '../../../Providers/jobsProvider.dart';
import '../../../Providers/newJobFormProvider.dart';
import '../../../core/Theme.dart';
import '../../../widgets/StatusBadge.dart';


class JobsScreen extends ConsumerWidget {

  const JobsScreen({super.key,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(jobFilterProvider);
    final filtered = ref.watch(filteredJobsProvider);
    final allJobs = ref.watch(jobsProvider);

    final counts = {
      'all': allJobs.length,
      'pending': allJobs.where((j) => j.status == 'pending').length,
      'in-progress': allJobs.where((j) => j.status == 'in-progress').length,
      'completed': allJobs.where((j) => j.status == 'completed').length,
    };

    final filters = [
      ('all', 'All (${counts['all']})'),
      ('pending', 'Pending (${counts['pending']})'),
      ('in-progress', 'In Progress (${counts['in-progress']})'),
      ('completed', 'Completed (${counts['completed']})'),
    ];

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
                    const Text('Job Cards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kForeground)),
                    GestureDetector(
                      onTap: (){context.push("/new-job");},
                      child: Container(
                        width: 38, height: 38,
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
                          selected: filter == f.$1,
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _JobCard(
                job: filtered[i],
                onTap: () {
                  ref.read(selectedJobProvider.notifier).state = filtered[i];
                 context.push("/job-detail");
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){context.push("/new-job");},
        backgroundColor: kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
                        const SizedBox(height: 2),
                        Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                      ],
                    ),
                    StatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${job.vehicle} · ${job.brand}', style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                const SizedBox(height: 2),
                Text(job.complaint, style: const TextStyle(fontSize: 12, color: kMutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(11)),
                          child: const Icon(Icons.build_rounded, size: 12, color: kPrimary),
                        ),
                        const SizedBox(width: 6),
                        Text(job.mechanic, style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                      ],
                    ),
                    Text(formatCurrency(job.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kForeground)),
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

// ─── Job Detail Screen ────────────────────────────────────────────────────────

class JobDetailScreen extends ConsumerStatefulWidget {

  const JobDetailScreen({super.key, });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  int _tabIndex = 0;

  final parts = [
    ('Engine Oil 10W-40 (1L)', 4, 520, 2080),
    ('Oil Filter – Universal', 1, 150, 150),
    ('Air Filter – Maruti Swift', 1, 220, 220),
  ];

  final timeline = [
    (Icons.receipt_long_rounded, '9:30 AM', 'Job card created', 'Advisor Ravi'),
    (Icons.visibility_rounded, '10:15 AM', 'Vehicle inspection started', 'Suresh K.'),
    (Icons.inventory_2_rounded, '11:00 AM', 'Parts ordered from inventory', 'Suresh K.'),
    (Icons.build_rounded, '2:00 PM', 'Repair in progress', 'Suresh K.'),
  ];

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(selectedJobProvider) ?? mockJobs[0];

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: kCard,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
              onPressed: () => AppScreen.jobs,
            ),
            title: Text(job.id),
            actions: [
              const Icon(Icons.edit_rounded, color: kForeground, size: 18),
              const SizedBox(width: 8),
              StatusBadge(status: job.status),
              const SizedBox(width: 12),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Vehicle card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0288D1)]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Vehicle', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                                Text(job.vehicle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                Text(job.brand, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _infoChip('Mechanic', job.mechanic)),
                            const SizedBox(width: 8),
                            Expanded(child: _infoChip('Date', '23 Jun')),
                            const SizedBox(width: 8),
                            Expanded(child: _infoChip('Amount', formatCurrency(job.amount))),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER COMPLAINT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          Text(job.complaint, style: const TextStyle(fontSize: 14, color: kForeground)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GarageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMutedForeground, letterSpacing: 0.8)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              AvatarWidget(initials: 'RK'),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  const Text('+91 9876543210', style: TextStyle(fontSize: 12, color: kMutedForeground)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Mark Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => AppScreen.invoice,
                            icon: const Icon(Icons.receipt_long_rounded, size: 16),
                            label: const Text('Generate Bill'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_tabIndex == 1) ...[
                    ...parts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GarageCard(
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.inventory_2_rounded, size: 18, color: kPrimary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                Text('Qty: ${p.$2} × ${formatCurrency(p.$3)}', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                              ],
                            )),
                            Text(formatCurrency(p.$4), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                      ),
                    )),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Parts Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(formatCurrency(parts.fold(0, (sum, p) => sum + p.$4)),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kPrimary)),
                        ],
                      ),
                    ),
                  ],

                  if (_tabIndex == 2) ...[
                    ...List.generate(timeline.length, (i) {
                      final t = timeline[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), shape: BoxShape.circle),
                                child: Icon(t.$1, size: 16, color: kPrimary),
                              ),
                              if (i < timeline.length - 1)
                                Container(width: 2, height: 50, color: kBorder),
                            ],
                          ),
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
                                  Text('${t.$2} · by ${t.$4}', style: const TextStyle(fontSize: 11, color: kMutedForeground)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── New Job Screen ───────────────────────────────────────────────────────────

class NewJobScreen extends ConsumerWidget {

  const NewJobScreen({super.key, });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(newJobFormProvider);

    void setStep(int s) => ref.read(newJobFormProvider.notifier).update((f) => f.copyWith(step: s));
    void setCustomer(customer) => ref.read(newJobFormProvider.notifier).update((f) => f.copyWith(customer: customer, step: 2));

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('New Job Card'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
          onPressed: () {
            ref.read(newJobFormProvider.notifier).state = const NewJobFormState();
           AppScreen.jobs;
          },
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                Row(
                  children: List.generate(3, (i) {
                    final s = i + 1;
                    return Expanded(
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: form.step >= s ? kPrimary : kMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: form.step > s
                                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                  : Text('$s', style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: form.step >= s ? Colors.white : kMutedForeground,
                              )),
                            ),
                          ),
                          if (i < 2) Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 2,
                              color: form.step > s ? kPrimary : kMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer', style: TextStyle(fontSize: 10, color: kMutedForeground)),
                    Text('Vehicle', style: TextStyle(fontSize: 10, color: kMutedForeground)),
                    Text('Details', style: TextStyle(fontSize: 10, color: kMutedForeground)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (form.step == 1) ...[
                    const Text('Search Customer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Row(
                        children: [
                          Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.search_rounded, color: kMutedForeground, size: 18)),
                          Expanded(child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Phone number or name...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...mockCustomers.take(4).map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GarageCard(
                        onTap: () => setCustomer(c),
                        child: Row(
                          children: [
                            AvatarWidget(initials: c.avatar),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                Text(c.phone, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                              ],
                            )),
                            const Icon(Icons.chevron_right_rounded, color: kMutedForeground),
                          ],
                        ),
                      ),
                    )),
                  ],

                  if (form.step == 2) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBCEED)),
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(initials: form.customer?.avatar ?? ''),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(form.customer?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              Text(form.customer?.phone ?? '', style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...['MH12 AB 1234', 'MH12 XY 9876'].map((v) {
                      final isCar = v.contains('1234');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(newJobFormProvider.notifier).update((f) => f.copyWith(selectedVehicle: v));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: form.selectedVehicle == v ? const Color(0xFFE8F0FE) : kCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: form.selectedVehicle == v ? kPrimary : kBorder),
                            ),
                            child: Row(
                              children: [
                                VehicleIcon(type: isCar ? 'car' : 'bike'),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    Text(isCar ? 'Maruti Swift' : 'Royal Enfield Bullet', style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                                  ],
                                )),
                                if (form.selectedVehicle == v)
                                  const Icon(Icons.check_rounded, color: kPrimary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: kPrimary, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: kPrimary, size: 18),
                          SizedBox(width: 6),
                          Text('Add New Vehicle', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: form.selectedVehicle.isNotEmpty ? () => setStep(3) : null,
                        child: const Text('Continue'),
                      ),
                    ),
                  ],

                  if (form.step == 3) ...[
                    const Text('Complaint / Problem Description', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: TextField(
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe the issue reported by customer...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                        ),
                        onChanged: (v) => ref.read(newJobFormProvider.notifier).update((f) => f.copyWith(complaint: v)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Assign Mechanic', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...['Suresh K.', 'Ramesh V.', 'Kiran M.'].map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => ref.read(newJobFormProvider.notifier).update((f) => f.copyWith(mechanic: m)),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: form.mechanic == m ? const Color(0xFFE8F0FE) : kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: form.mechanic == m ? kPrimary : kBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), shape: BoxShape.circle),
                                child: Center(child: Text(m.split(' ').map((p) => p[0]).join(''),
                                    style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  const Text('Senior Mechanic', style: TextStyle(fontSize: 11, color: kMutedForeground)),
                                ],
                              )),
                              if (form.mechanic == m) const Icon(Icons.check_rounded, color: kPrimary),
                            ],
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 8),
                    const Text('Add Photos (Optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 28, color: kMutedForeground),
                          SizedBox(height: 6),
                          Text('Tap to add photos of damage', style: TextStyle(color: kMutedForeground, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(newJobFormProvider.notifier).state = const NewJobFormState();
                          AppScreen.jobDetail;
                        },
                        child: const Text('Create Job Card'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}