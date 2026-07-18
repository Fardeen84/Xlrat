// lib/screen/navigation_screen/ProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xlrat/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/billing_providers.dart';
import '../../providers/jobsProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatCurrencyCompact(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final displayName = profile.garageName.isNotEmpty
        ? profile.garageName
        : 'My Garage';
    final gstDisplay = profile.gstNumber.isNotEmpty
        ? profile.gstNumber
        : 'Not set';
    final addressDisplay = profile.address.isNotEmpty
        ? profile.address
        : 'Not set';

    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    final customersAsync = ref.watch(customerListProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final invoicesAsync = ref.watch(invoiceListProvider);

    final customerCount = customersAsync.value?.length ?? 0;
    final completedJobsCount =
        jobsAsync.value?.where((j) => j.status == 'completed').length ?? 0;
    final totalRevenue =
        invoicesAsync.value?.fold<double>(
          0.0,
          (sum, inv) => sum + inv.grandTotal,
        ) ??
        0.0;

    final sections = [
      _Section('Workshop', [
        _Item(
          Icons.store_rounded,
          'Workshop Details',
          displayName,
          id: 'workshop',
        ),
        _Item(
          Icons.engineering_rounded,
          'Manage Mechanics',
          'Add, edit, or remove workshop mechanics',
          id: 'mechanics',
        ),
        _Item(
          Icons.shield_rounded,
          'GST & Tax Settings',
          gstDisplay,
          id: 'gst',
        ),
        _Item(
          Icons.location_on_rounded,
          'Address & Location',
          addressDisplay,
          id: 'address',
        ),
        _Item(
          Icons.vpn_key_rounded,
          'Garage Code',
          profile.garageId.isNotEmpty ? profile.garageId : 'Not set',
          id: 'garage_code',
        ),
      ]),
      _Section('App Settings', [
        _Item(Icons.print_rounded, 'Printer Settings', 'Bluetooth thermal'),
        _Item(
          Icons.palette_rounded,
          'Theme & Display',
          themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
          id: 'theme',
        ),
        _Item(Icons.notifications_rounded, 'Notifications', 'All enabled'),
        _Item(
          Icons.language_rounded,
          l10n.profileLanguageSetting,
          locale.languageCode == 'en' ? 'English' : 'हिंदी',
          id: 'language',
        ),
      ]),
      _Section('Account', [
        _Item(Icons.person_rounded, 'My Profile', displayName, id: 'profile'),
        _Item(Icons.lock_rounded, 'Security & PIN', 'Biometric enabled'),
        _Item(Icons.help_outline_rounded, 'Help & Support', 'v2.4.1'),
      ]),
    ];

    return Scaffold(
      backgroundColor: kBackground,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDB913), Color(0xFFFDB918)],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 32,
              left: 16,
              right: 16,
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName
                                .split(' ')
                                .map((e) => e.isNotEmpty ? e[0] : '')
                                .take(2)
                                .join('')
                                .toUpperCase()
                          : 'MG',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Garage Owner · $displayName',
                  style: TextStyle(color: Colors.yellow[200], fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_chip('Premium Plan')],
                ),
              ],
            ),
          ),

          // Stats Row
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorder.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _statItem('$customerCount', 'Customers'),
                  _divider(),
                  _statItem('$completedJobsCount', 'Jobs Done'),
                  _divider(),
                  _statItem(_formatCurrencyCompact(totalRevenue), 'Revenue'),
                ],
              ),
            ),
          ),

          // Settings Sections
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      section.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: kMutedForeground,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: section.items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 18,
                                  color: kPrimary,
                                ),
                              ),
                              title: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kForeground,
                                ),
                              ),
                              subtitle: Text(
                                item.sub,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kMutedForeground,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: kMutedForeground,
                              ),
                              onTap: () {
                                if (item.id == 'workshop') {
                                  _showEditGarageNameDialog(
                                    context,
                                    ref,
                                    displayName,
                                  );
                                } else if (item.id == 'gst') {
                                  _showEditGstDialog(
                                    context,
                                    ref,
                                    profile.gstNumber,
                                  );
                                } else if (item.id == 'address') {
                                  _showEditAddressDialog(
                                    context,
                                    ref,
                                    profile.address,
                                  );
                                } else if (item.id == 'mechanics') {
                                  context.push('/mechanics');
                                } else if (item.id == 'language') {
                                  _showLanguageDialog(context, ref);
                                } else if (item.id == 'theme') {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .toggleTheme();
                                } else if (item.id == 'garage_code') {
                                  if (profile.garageId.isNotEmpty) {
                                    Clipboard.setData(ClipboardData(text: profile.garageId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Garage code copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            if (i < section.items.length - 1)
                              Divider(height: 1, indent: 70, color: kBorder),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Leave Garage
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showLeaveGarageDialog(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Leave Garage',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGarageNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Workshop Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter garage name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(profileProvider.notifier)
                    .updateGarageName(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGstDialog(
    BuildContext context,
    WidgetRef ref,
    String currentGst,
  ) {
    final controller = TextEditingController(text: currentGst);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit GST Number'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter GST number'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(profileProvider.notifier)
                    .updateGstNumber(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAddressDialog(
    BuildContext context,
    WidgetRef ref,
    String currentAddress,
  ) {
    final controller = TextEditingController(text: currentAddress);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Address'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Enter garage address'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(profileProvider.notifier)
                    .updateAddress(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final currentLanguageCode = ref.read(localeProvider).languageCode;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.profileLanguageSelect),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                trailing: currentLanguageCode == 'en'
                    ? const Icon(Icons.check, color: kPrimary)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('हिंदी (Hindi)'),
                trailing: currentLanguageCode == 'hi'
                    ? const Icon(Icons.check, color: kPrimary)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('hi');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaveGarageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Leave Garage'),
          content: const Text('Are you sure you want to leave this garage? You will need a garage code to rejoin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(uid).set({
                      'garageId': '',
                    }, SetOptions(merge: true));
                  } catch (e) {
                    print('Error leaving garage in Firestore: $e');
                  }
                }
                ref.read(profileProvider.notifier).clearProfile();
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _statItem(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: kForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: kMutedForeground)),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 36, color: kBorder);
}

class _Section {
  final String title;
  final List<_Item> items;
  const _Section(this.title, this.items);
}

class _Item {
  final IconData icon;
  final String label, sub;
  final String? id;
  const _Item(this.icon, this.label, this.sub, {this.id});
}
