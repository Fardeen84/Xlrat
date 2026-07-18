import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../providers/profile_provider.dart';

class SetupGarageScreen extends ConsumerStatefulWidget {
  const SetupGarageScreen({super.key});

  @override
  ConsumerState<SetupGarageScreen> createState() => _SetupGarageScreenState();
}

class _SetupGarageScreenState extends ConsumerState<SetupGarageScreen> {
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createGarage() async {
    if (!_createFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User is not authenticated");

      final newGarageId = const Uuid().v4();
      final garageName = _nameController.text.trim();

      // 1. Write users/{uid}.garageId = newGarageId
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'garageId': newGarageId,
      }, SetOptions(merge: true));

      // 2. Create the garages/{newGarageId} document
      await FirebaseFirestore.instance.collection('garages').doc(newGarageId).set({
        'name': garageName,
        'gstNumber': '',
        'address': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update profile provider
      ref.read(profileProvider.notifier).updateProfile(
        garageId: newGarageId,
        garageName: garageName,
        gstNumber: '',
        address: '',
      );

      setState(() {
        _successMessage = "Garage created successfully!";
      });

      // Router redirect or refreshListenable will send us to /dashboard
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to create garage: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGarage(String code) async {
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _errorMessage = "User not authenticated";
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. WRITE users/{uid}.garageId = enteredCode
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'garageId': code,
      }, SetOptions(merge: true));

      // 2. Attempt to READ garages/{enteredCode}
      final doc = await FirebaseFirestore.instance.collection('garages').doc(code).get();

      if (!doc.exists) {
        // Rollback: clear users/{uid}.garageId
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'garageId': '',
        }, SetOptions(merge: true));

        throw Exception("Garage code not found");
      }

      final data = doc.data() ?? {};
      final name = data['name'] as String? ?? 'My Garage';
      final gst = data['gstNumber'] as String? ?? '';
      final address = data['address'] as String? ?? '';

      // 3. Update profile provider
      ref.read(profileProvider.notifier).updateProfile(
        garageId: code,
        garageName: name,
        gstNumber: gst,
        address: address,
      );

      setState(() {
        _successMessage = "Joined garage successfully!";
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains("Garage code not found")
            ? "Garage code not found. Please try again."
            : "Failed to join garage: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importLocalGarage(String cachedGarageId) async {
    if (cachedGarageId.isEmpty) return;
    await _joinGarage(cachedGarageId);
  }

  @override
  Widget build(BuildContext context) {
    // Read the cached garageId from SharedPreferences (currently in profile state if not overwritten)
    final profile = ref.watch(profileProvider);
    final cachedGarageId = profile.garageId;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Garage Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to GarageOS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: kForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To get started, you can create a new garage profile, join an existing one shared by your team, or import your local data.',
                style: TextStyle(
                  fontSize: 14,
                  color: kMutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: kRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: kRed, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: kGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: kGreen, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 24),
              ],

              // Card Option 1: Create a New Garage
              Card(
                color: kCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: kBorder.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _createFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add_business_rounded, color: kPrimary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Create New Garage',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Garage/Workshop Name',
                            hintText: 'e.g. Speed Motors',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a garage name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createGarage,
                            child: const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card Option 2: Join an Existing Garage
              Card(
                color: kCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: kBorder.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _joinFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.group_add_rounded, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Join Existing Garage',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Garage Invite Code',
                            hintText: 'Enter the UUID code from device A',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a garage code';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _joinGarage(_codeController.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kPrimaryDark,
                            ),
                            child: const Text('Join'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card Option 3: Import Existing Data from This Device
              if (cachedGarageId.isNotEmpty) ...[
                Card(
                  color: kCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: kBorder.withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.import_export_rounded, color: kGreen),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Import Device Data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Found an existing local garage profile on this device:',
                          style: TextStyle(fontSize: 13, color: kMutedForeground),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cachedGarageId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _importLocalGarage(cachedGarageId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: kGreen, width: 1.5),
                            ),
                            child: const Text('Import Existing Data'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
