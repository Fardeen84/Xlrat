// lib/screens/jobs/new_job_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../widgets/StatusBadge.dart';

class NewJobScreen extends StatefulWidget {
  const NewJobScreen({super.key});

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  int _step = 1;
  String? _selectedCustomer;
  String _selectedVehicle = '';
  String _mechanic = '';

  static const _customers = [
    ('Rajesh Kumar', '+91 9876543210', 'RK'),
    ('Priya Sharma', '+91 9812345678', 'PS'),
    ('Mohammed Irfan', '+91 9988776655', 'MI'),
    ('Sunita Patel', '+91 9765432109', 'SP'),
  ];

  static const _vehicles = [
    ('MH12 AB 1234', 'Maruti Swift VXI', 'car'),
    ('MH12 XY 9876', 'Royal Enfield Bullet 350', 'bike'),
  ];

  static const _mechanics = [
    ('Suresh K.', 'SK'),
    ('Ramesh V.', 'RV'),
    ('Kiran M.', 'KM'),
  ];

  @override
  Widget build(BuildContext context) {
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
                      child: const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(Icons.search_rounded, color: kMutedForeground, size: 18),
                          ),
                          Expanded(
                            child: TextField(
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
                    ..._customers.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GarageCard(
                        onTap: () => setState(() { _selectedCustomer = c.$1; _step = 2; }),
                        child: Row(children: [
                          AvatarWidget(initials: c.$3),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                            Text(c.$2, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                          ])),
                          const Icon(Icons.chevron_right_rounded, color: kMutedForeground),
                        ]),
                      ),
                    )),
                  ],

                  // Step 2: Vehicle
                  if (_step == 2) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(children: [
                        AvatarWidget(initials: _selectedCustomer?.split(' ').map((e) => e[0]).join('') ?? ''),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_selectedCustomer ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const Text('+91 9876543210',
                              style: TextStyle(fontSize: 12, color: kMutedForeground)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Vehicle',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kForeground)),
                    const SizedBox(height: 8),
                    ..._vehicles.map((v) {
                      final isSelected = _selectedVehicle == v.$1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedVehicle = v.$1),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : kCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? kPrimary : kBorder),
                            ),
                            child: Row(children: [
                              VehicleIcon(type: v.$3),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(v.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                Text(v.$2, style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                              ])),
                              if (isSelected)
                                const Icon(Icons.check_rounded, color: kPrimary, size: 20),
                            ]),
                          ),
                        ),
                      );
                    }),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kPrimary),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: kPrimary, size: 18),
                          SizedBox(width: 6),
                          Text('Add New Vehicle',
                              style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedVehicle.isNotEmpty ? () => setState(() => _step = 3) : null,
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
                      child: const TextField(
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
                        onPressed: () => context.go('/job-detail'),
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