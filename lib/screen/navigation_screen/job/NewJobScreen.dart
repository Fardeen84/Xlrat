import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../models/job.dart';
import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../providers/billing_providers.dart';
import '../../../providers/jobsProvider.dart';

class NewJobScreen extends ConsumerStatefulWidget {
  const NewJobScreen({super.key});

  @override
  ConsumerState<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends ConsumerState<NewJobScreen> {
  int _step = 1;
  BillingCustomer? _selectedCustomer;
  BillingVehicle? _selectedVehicle;
  String _mechanic = '';
  String _searchQuery = '';
  final _complaintController = TextEditingController();

  static const _mechanics = [
    ('Suresh K.', 'SK'),
    ('Ramesh V.', 'RV'),
    ('Kiran M.', 'KM'),
  ];

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch real database customers
    final customersAsync = ref.watch(customerListProvider);
    final customers = customersAsync.value ?? [];

    // Filter customers based on search query
    final filteredCustomers = customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.mobile.contains(q);
    }).toList();

    // Watch real database vehicles for selected customer
    final vehiclesAsync = _selectedCustomer != null
        ? ref.watch(vehiclesForCustomerProvider(_selectedCustomer!.id!))
        : null;
    final vehicles = vehiclesAsync?.value ?? [];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kForeground),
          onPressed: () => context.go('/jobs'),
        ),
        title: const Text('New Job Card',
            style: TextStyle(fontWeight: FontWeight.w800, color: kForeground, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Step Indicator
          Container(
            color: kCard,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Row(
                  children: List.generate(3, (i) {
                    final s = i + 1;
                    final isDone = _step > s;
                    final isActive = _step == s;
                    return Expanded(
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: (_step >= s) ? kPrimary : kMuted,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                  : Text('$s',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isActive ? Colors.white : kMutedForeground,
                                  )),
                            ),
                          ),
                          if (i < 2)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 2,
                                color: _step > s ? kPrimary : kMuted,
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
                  // Step 1: Customer
                  if (_step == 1) ...[
                    const Text('Search Customer',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(Icons.search_rounded, color: kMutedForeground, size: 18),
                          ),
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              decoration: const InputDecoration(
                                hintText: 'Phone number or name...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                hintStyle: TextStyle(color: kMutedForeground),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (customersAsync.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (filteredCustomers.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No customers found', style: TextStyle(color: kMutedForeground)),
                      ))
                    else
                      ...filteredCustomers.map((c) {
                        final initials = c.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GarageCard(
                            onTap: () => setState(() { _selectedCustomer = c; _step = 2; }),
                            child: Row(children: [
                              AvatarWidget(initials: initials.isEmpty ? '?' : initials),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                                Text(c.mobile, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                              ])),
                              const Icon(Icons.chevron_right_rounded, color: kMutedForeground),
                            ]),
                          ),
                        );
                      }),
                  ],

                  // Step 2: Vehicle
                  if (_step == 2 && _selectedCustomer != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(children: [
                        AvatarWidget(initials: _selectedCustomer!.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_selectedCustomer!.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text(_selectedCustomer!.mobile,
                              style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Vehicle',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    const SizedBox(height: 8),
                    if (vehiclesAsync != null && vehiclesAsync.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (vehicles.isEmpty)
                      Column(
                        children: [
                          const Center(child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No vehicles added for this customer yet.', style: TextStyle(color: kMutedForeground)),
                          )),
                          const SizedBox(height: 8),
                          // Allow typing vehicle registration or navigating to add it
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kPrimary),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Navigate to customer details to add a vehicle
                                context.push('/customer-detail/${_selectedCustomer!.id}');
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: kPrimary, size: 18),
                                  SizedBox(width: 6),
                                  Text('Add Vehicle in Customer Details',
                                      style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ...vehicles.map((v) {
                        final isSelected = _selectedVehicle?.id == v.id;
                        final type = v.fuelType.toLowerCase().contains('diesel') || v.fuelType.toLowerCase().contains('petrol') ? 'car' : 'bike';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedVehicle = v),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEFF6FF) : kCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? kPrimary : kBorder),
                              ),
                              child: Row(children: [
                                VehicleIcon(type: type),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  Text('${v.vehicleBrand} ${v.vehicleModel}', style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                                ])),
                                if (isSelected)
                                  const Icon(Icons.check_rounded, color: kPrimary, size: 20),
                              ]),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedVehicle != null ? () => setState(() => _step = 3) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kPrimary.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],

                  // Step 3: Details
                  if (_step == 3) ...[
                    const Text('Complaint / Problem Description',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: TextField(
                        controller: _complaintController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe the issue reported by customer...',
                          hintStyle: TextStyle(color: kMutedForeground),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Assign Mechanic',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    const SizedBox(height: 8),
                    ..._mechanics.map((m) {
                      final isSelected = _mechanic == m.$1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _mechanic = m.$1),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : kCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? kPrimary : kBorder),
                            ),
                            child: Row(children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(m.$2,
                                      style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const Text('Senior Mechanic',
                                    style: TextStyle(fontSize: 11, color: kMutedForeground)),
                              ])),
                              if (isSelected)
                                const Icon(Icons.check_rounded, color: kPrimary, size: 20),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    const Text('Add Photos (Optional)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 28, color: kMutedForeground),
                          SizedBox(height: 6),
                          Text('Tap to add photos of damage',
                              style: TextStyle(color: kMutedForeground, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final repo = ref.read(jobRepositoryProvider);
                          final nextJobNumber = await repo.generateNextJobNumber();
                          final type = _selectedVehicle != null
                              ? (_selectedVehicle!.vehicleModel.toLowerCase().contains('bullet') ||
                                      _selectedVehicle!.vehicleModel.toLowerCase().contains('activa') ||
                                      _selectedVehicle!.vehicleBrand.toLowerCase().contains('honda') ||
                                      _selectedVehicle!.vehicleBrand.toLowerCase().contains('bajaj')
                                  ? 'bike'
                                  : 'car')
                              : 'car';
                          final job = Job(
                            jobNumber: nextJobNumber,
                            customer: _selectedCustomer?.name ?? 'Unknown',
                            vehicle: _selectedVehicle?.vehicleNumber ?? 'Unknown',
                            vehicleType: type,
                            brand: _selectedVehicle != null ? '${_selectedVehicle!.vehicleBrand} ${_selectedVehicle!.vehicleModel}' : 'Unknown',
                            complaint: _complaintController.text.trim(),
                            mechanic: _mechanic.isNotEmpty ? _mechanic : 'Suresh K.',
                            status: 'pending',
                            date: DateFormat('dd MMM yyyy').format(DateTime.now()),
                            amount: 0,
                          );
                          final router = GoRouter.of(context);
                          final savedJob = await repo.createJob(job);
                          ref.invalidate(jobsProvider);
                          if (mounted) {
                            router.go('/job-detail/${savedJob.id}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Create Job Card', style: TextStyle(fontWeight: FontWeight.w800)),
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