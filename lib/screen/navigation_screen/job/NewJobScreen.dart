import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../widgets/StatusBadge.dart';
import '../../../widgets/QuickAddSheets.dart';
import '../../../models/job.dart';
import '../../../models/billing_model/BillingCustomer.dart';
import '../../../models/billing_model/BillingVehicle.dart';
import '../../../providers/billing_providers.dart';
import '../../../providers/jobsProvider.dart';
import '../../../providers/newJobFormProvider.dart';
import '../../../models/NewJobFormState.dart';
import '../../../models/Mechanic.dart';
import '../../../providers/mechanicsProvider.dart';


class NewJobScreen extends ConsumerStatefulWidget {
  const NewJobScreen({super.key});

  @override
  ConsumerState<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends ConsumerState<NewJobScreen> {
  int _step = 1;
  BillingCustomer? _selectedCustomer;
  BillingVehicle? _selectedVehicle;
  List<String> _mechanics = [];
  String _searchQuery = '';
  String _jobType = 'vehicle';
  final _complaintController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemDescriptionController = TextEditingController();

  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }


  @override
  void initState() {
    super.initState();
    final state = ref.read(newJobFormProvider);
    _step = state.step;
    _selectedCustomer = state.customer;
    _selectedVehicle = state.vehicle;
    _mechanics = state.mechanics;
    _jobType = state.jobType;
    _complaintController.text = state.complaint;
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    super.dispose();
  }

  void _updateState({
    int? step,
    BillingCustomer? customer,
    BillingVehicle? vehicle,
    String? complaint,
    List<String>? mechanics,
    String? jobType,
  }) {
    ref.read(newJobFormProvider.notifier).update((state) => state.copyWith(
      step: step ?? _step,
      customer: customer ?? _selectedCustomer,
      vehicle: vehicle ?? _selectedVehicle,
      complaint: complaint ?? _complaintController.text,
      mechanics: mechanics ?? _mechanics,
      jobType: jobType ?? _jobType,
    ));
  }

  void _changeStep(int step) {
    setState(() {
      _step = step;
    });
    _updateState(step: step);
  }

  void _selectCustomer(BillingCustomer customer) {
    setState(() {
      _selectedCustomer = customer;
      _step = 2;
    });
    _updateState(step: 2, customer: customer);
  }

  void _selectVehicle(BillingVehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
    });
    _updateState(vehicle: vehicle);
  }

  void _selectMechanic(String mechanic) {
    setState(() {
      if (_mechanics.contains(mechanic)) {
        _mechanics = _mechanics.where((m) => m != mechanic).toList();
      } else {
        _mechanics = [..._mechanics, mechanic];
      }
    });
    _updateState(mechanics: _mechanics);
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider and synchronize local state fields immediately when changed.
    // This is robust against widget reuse and state updates before navigation.
    final formState = ref.watch(newJobFormProvider);
    if (_step != formState.step ||
        _selectedCustomer != formState.customer ||
        _selectedVehicle != formState.vehicle ||
        !_areListsEqual(_mechanics, formState.mechanics) ||
        _jobType != formState.jobType) {
      _step = formState.step;
      _selectedCustomer = formState.customer;
      _selectedVehicle = formState.vehicle;
      _mechanics = formState.mechanics;
      _jobType = formState.jobType;
      if (_complaintController.text != formState.complaint) {
        _complaintController.text = formState.complaint;
      }
    }

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
          icon: Icon(Icons.arrow_back_rounded, color: kForeground),
          onPressed: () {
            ref.invalidate(newJobFormProvider);
            context.go('/jobs');
          },
        ),
        title: Text('New Job Card',
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
                SizedBox(height: 6),
                Row(
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
                    Text('Search Customer',
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
                          Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(Icons.search_rounded, color: kMutedForeground, size: 18),
                          ),
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              decoration: InputDecoration(
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
                    else ...[
                      if (_searchQuery.isNotEmpty && !filteredCustomers.any((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || c.mobile.contains(_searchQuery)))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GarageCard(
                            color: kPrimary.withOpacity(0.05),
                            onTap: () {
                              QuickAddSheets.showAddCustomer(context, ref, onSaved: (newCust) {
                                _selectCustomer(newCust);
                              });
                            },
                            child: Row(children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: kPrimary,
                                child: Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                              ),
                              SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Quick Add Customer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kPrimary)),
                                Text('Create new customer record', style: TextStyle(fontSize: 12, color: kMutedForeground)),
                              ])),
                              Icon(Icons.chevron_right_rounded, color: kPrimary),
                            ]),
                          ),
                        ),
                      ...filteredCustomers.map((c) {
                        final initials = c.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GarageCard(
                            onTap: () => _selectCustomer(c),
                            child: Row(children: [
                              AvatarWidget(initials: initials.isEmpty ? '?' : initials),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                                Text(c.mobile, style: TextStyle(fontSize: 12, color: kMutedForeground)),
                              ])),
                              Icon(Icons.chevron_right_rounded, color: kMutedForeground),
                            ]),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            QuickAddSheets.showAddCustomer(context, ref, onSaved: (newCust) {
                              _selectCustomer(newCust);
                            });
                          },
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text('Quick Add Customer'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
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
                              style: TextStyle(fontSize: 12, color: kMutedForeground)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Toggle Vehicle vs Item Job
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kMuted.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _jobType = 'vehicle';
                                });
                                _updateState(jobType: 'vehicle');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _jobType == 'vehicle' ? kCard : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _jobType == 'vehicle'
                                      ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Vehicle Job',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _jobType == 'vehicle' ? kForeground : kMutedForeground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _jobType = 'item';
                                });
                                _updateState(jobType: 'item');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _jobType == 'item' ? kCard : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _jobType == 'item'
                                      ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Item Job',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _jobType == 'item' ? kForeground : kMutedForeground,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_jobType == 'vehicle') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Vehicle',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                          TextButton.icon(
                            onPressed: () {
                              QuickAddSheets.showAddVehicle(
                                context,
                                ref,
                                customerId: _selectedCustomer!.id!,
                                onSaved: (newVehicle) {
                                  _selectVehicle(newVehicle);
                                },
                              );
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Quick Add Vehicle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (vehiclesAsync != null && vehiclesAsync.isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (vehicles.isEmpty)
                        Column(
                          children: [
                            Center(child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('No vehicles added for this customer yet.', style: TextStyle(color: kMutedForeground)),
                            )),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                QuickAddSheets.showAddVehicle(
                                  context,
                                  ref,
                                  customerId: _selectedCustomer!.id!,
                                  onSaved: (newVehicle) {
                                    _selectVehicle(newVehicle);
                                  },
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Quick Add Vehicle'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        )
                      else ...[
                          ...vehicles.map((v) {
                            final isSelected = _selectedVehicle?.id == v.id;
                            final type = v.fuelType.toLowerCase().contains('diesel') || v.fuelType.toLowerCase().contains('petrol') ? 'car' : 'bike';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => _selectVehicle(v),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEFF6FF) : kCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? kPrimary : kBorder),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : const Color(0xFFF5F7FA),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        type == 'bike' ? Icons.motorcycle_rounded : Icons.directions_car_rounded,
                                        color: isSelected ? kPrimary : kMutedForeground,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('${v.vehicleBrand} ${v.vehicleModel}',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text(v.vehicleNumber,
                                          style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.bold)),
                                    ])),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: kPrimary, size: 20)
                                    else
                                      Icon(Icons.circle_outlined, color: kBorder, size: 20),
                                  ]),
                                ),
                              ),
                            );
                          }),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                QuickAddSheets.showAddVehicle(
                                  context,
                                  ref,
                                  customerId: _selectedCustomer!.id!,
                                  onSaved: (newVehicle) {
                                    _selectVehicle(newVehicle);
                                  },
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Another Vehicle'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                    ],
                    if (_jobType == 'item') ...[
                      Text('Item Details',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder),
                        ),
                        child: TextFormField(
                          controller: _itemNameController,
                          onChanged: (val) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Item Name *',
                            labelStyle: TextStyle(color: kMutedForeground),
                            hintText: 'e.g. Alternator, Gearbox Casing, Radiator',
                            hintStyle: TextStyle(color: kMutedForeground.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(color: kForeground),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder),
                        ),
                        child: TextFormField(
                          controller: _itemDescriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Item Description / Notes (Optional)',
                            labelStyle: TextStyle(color: kMutedForeground),
                            hintText: 'Any extra details about the item',
                            hintStyle: TextStyle(color: kMutedForeground.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(color: kForeground),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _changeStep(1),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _jobType == 'vehicle'
                                ? (_selectedVehicle == null ? null : () => _changeStep(3))
                                : (_itemNameController.text.trim().isEmpty ? null : () => _changeStep(3)),
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
                    ),
                  ],

                  // Step 3: Details
                  if (_step == 3) ...[
                    Text('Complaint / Problem Description',
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
                        onChanged: (val) => _updateState(complaint: val),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe the issue reported by customer...',
                          hintStyle: TextStyle(color: kMutedForeground),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Assign Mechanic',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    const SizedBox(height: 8),
                    ref.watch(mechanicListProvider).when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Error loading mechanics: $err',
                            style: const TextStyle(color: kRed, fontSize: 13),
                          ),
                        ),
                      ),
                      data: (mechanics) {
                        if (mechanics.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'No mechanics added yet — add one from Profile → Manage Mechanics',
                              style: TextStyle(
                                fontSize: 13,
                                color: kMutedForeground,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: mechanics.map((m) {
                            final isSelected = _mechanics.contains(m.name);
                            final initials = m.initials.trim().isNotEmpty
                                ? m.initials.trim().toUpperCase()
                                : m.name
                                .trim()
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join('')
                                .toUpperCase();
                            final avatarText = initials.isNotEmpty ? initials : '?';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => _selectMechanic(m.name),
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
                                        child: Text(avatarText,
                                            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      if (m.specialization.isNotEmpty)
                                        Text(m.specialization,
                                            style: TextStyle(fontSize: 11, color: kMutedForeground))
                                      else
                                        Text('Mechanic',
                                            style: TextStyle(fontSize: 11, color: kMutedForeground)),
                                    ])),
                                    if (isSelected)
                                      const Icon(Icons.check_rounded, color: kPrimary, size: 20),
                                  ]),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Text('Add Photos (Optional)',
                    //     style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    // const SizedBox(height: 8),
                    // Container(
                    //   width: double.infinity,
                    //   padding: EdgeInsets.symmetric(vertical: 28),
                    //   decoration: BoxDecoration(
                    //     color: kCard,
                    //     borderRadius: BorderRadius.circular(16),
                    //     border: Border.all(color: kBorder),
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Icon(Icons.camera_alt_rounded, size: 28, color: kMutedForeground),
                    //       SizedBox(height: 6),
                    //       Text('Tap to add photos of damage',
                    //           style: TextStyle(color: kMutedForeground, fontSize: 13)),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _changeStep(2),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final repo = ref.read(jobRepositoryProvider);
                              final nextJobNumber = await repo.generateNextJobNumber();
                              final Job job;
                              if (_jobType == 'item') {
                                job = Job(
                                  jobNumber: nextJobNumber,
                                  customer: _selectedCustomer?.name ?? 'Unknown',
                                  vehicle: _itemNameController.text.trim(),
                                  vehicleType: 'item',
                                  brand: '',
                                  complaint: _complaintController.text.trim(),
                                  mechanics: _mechanics,
                                  status: 'pending',
                                  date: DateFormat('dd MMM yyyy').format(DateTime.now()),
                                  amount: 0,
                                  customerId: _selectedCustomer?.id,
                                  vehicleId: null,
                                  jobType: 'item',
                                  itemName: _itemNameController.text.trim(),
                                  itemDescription: _itemDescriptionController.text.trim(),
                                );
                              } else {
                                final type = _selectedVehicle != null
                                    ? (_selectedVehicle!.vehicleModel.toLowerCase().contains('bullet') ||
                                    _selectedVehicle!.vehicleModel.toLowerCase().contains('activa') ||
                                    _selectedVehicle!.vehicleBrand.toLowerCase().contains('honda') ||
                                    _selectedVehicle!.vehicleBrand.toLowerCase().contains('bajaj')
                                    ? 'bike'
                                    : 'car')
                                    : 'car';
                                job = Job(
                                  jobNumber: nextJobNumber,
                                  customer: _selectedCustomer?.name ?? 'Unknown',
                                  vehicle: _selectedVehicle?.vehicleNumber ?? 'Unknown',
                                  vehicleType: type,
                                  brand: _selectedVehicle != null ? '${_selectedVehicle!.vehicleBrand} ${_selectedVehicle!.vehicleModel}' : 'Unknown',
                                  complaint: _complaintController.text.trim(),
                                  mechanics: _mechanics,
                                  status: 'pending',
                                  date: DateFormat('dd MMM yyyy').format(DateTime.now()),
                                  amount: 0,
                                  customerId: _selectedCustomer?.id,
                                  vehicleId: _selectedVehicle?.id,
                                  jobType: 'vehicle',
                                  itemName: '',
                                  itemDescription: '',
                                );
                              }
                              final router = GoRouter.of(context);
                              final savedJob = await repo.createJob(job);
                              ref.invalidate(newJobFormProvider);
                              ref.invalidate(jobsListStateProvider);
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
                      ],
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