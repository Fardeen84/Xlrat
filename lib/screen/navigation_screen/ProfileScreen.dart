// lib/screen/navigation_screen/ProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xlrat/l10n/app_localizations.dart';

import '../../core/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garageName = ref.watch(profileProvider);
    final displayName = garageName.isNotEmpty ? garageName : 'My Garage';
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    final sections = [
      _Section('Workshop', [
        _Item(Icons.store_rounded, 'Workshop Details', displayName, id: 'workshop'),
        _Item(Icons.shield_rounded, 'GST & Tax Settings', '27AABCV1234A1ZB'),
        _Item(Icons.location_on_rounded, 'Address & Location', 'Pune, Maharashtra'),
      ]),
      _Section('App Settings', [
        _Item(Icons.print_rounded, 'Printer Settings', 'Bluetooth thermal'),
        _Item(Icons.palette_rounded, 'Theme & Display', 'Light mode'),
        _Item(Icons.notifications_rounded, 'Notifications', 'All enabled'),
        _Item(Icons.language_rounded, l10n.profileLanguageSetting, locale.languageCode == 'en' ? 'English' : 'हिंदी', id: 'language'),
      ]),
      _Section('Account', [
        _Item(Icons.person_rounded, 'My Profile', 'Asian auto repair'),
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
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
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
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Center(
                    child: Text('VS',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Asian auto repair',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Garage Owner · $displayName',
                    style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('⭐ Premium Plan'),
                    const SizedBox(width: 8),
                    _chip('Since 2021'),
                  ],
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  _statItem('1,284', 'Customers'),
                  _divider(),
                  _statItem('3,421', 'Jobs Done'),
                  _divider(),
                  _statItem('₹28.4L', 'Revenue'),
                ],
              ),
            ),
          ),

          // Settings Sections
          ...sections.map((section) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(section.title.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                          color: kMutedForeground, letterSpacing: 0.8)),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder.withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                  ),
                  child: Column(
                    children: section.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, size: 18, color: kPrimary),
                            ),
                            title: Text(item.label,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kForeground)),
                            subtitle: Text(item.sub,
                                style: const TextStyle(fontSize: 12, color: kMutedForeground)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: kMutedForeground),
                            onTap: () {
                              if (item.id == 'workshop') {
                                _showEditGarageNameDialog(context, ref, displayName);
                              } else if (item.id == 'language') {
                                _showLanguageDialog(context, ref);
                              }
                            },
                          ),
                          if (i < section.items.length - 1)
                            const Divider(height: 1, indent: 70, color: kBorder),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )),

          // Sign Out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => context.go('/login'),
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
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGarageNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Workshop Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter garage name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(profileProvider.notifier).updateGarageName(controller.text.trim());
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

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _statItem(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kForeground)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: kMutedForeground)),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 36, color: kBorder);
}

class _Section { final String title; final List<_Item> items; const _Section(this.title, this.items); }
class _Item {
  final IconData icon;
  final String label, sub;
  final String? id;
  const _Item(this.icon, this.label, this.sub, {this.id});
}