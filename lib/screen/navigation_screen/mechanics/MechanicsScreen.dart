import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/Theme.dart';
import '../../../models/Mechanic.dart';
import '../../../providers/mechanicsProvider.dart';
import '../../../widgets/EmptyStateView.dart';
import '../../../widgets/StatusBadge.dart';

class MechanicsScreen extends ConsumerStatefulWidget {
  const MechanicsScreen({super.key});

  @override
  ConsumerState<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends ConsumerState<MechanicsScreen> {
  String deriveInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    final first = parts[0][0];
    final last = parts[parts.length - 1][0];
    return '$first$last'.toUpperCase();
  }

  void _showAddEditMechanicDialog(BuildContext context, [Mechanic? mechanic]) {
    final isEdit = mechanic != null;
    final nameController = TextEditingController(text: mechanic?.name ?? '');
    final initialsController = TextEditingController(text: mechanic?.initials ?? '');
    final phoneController = TextEditingController(text: mechanic?.phone ?? '');
    final specializationController = TextEditingController(text: mechanic?.specialization ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: kCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit Mechanic' : 'Add Mechanic',
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
                        controller: initialsController,
                        decoration: InputDecoration(
                          labelText: 'Initials (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                          hintText: 'Auto-derived if left blank',
                          hintStyle: TextStyle(color: kMutedForeground.withOpacity(0.5)),
                        ),
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: kForeground),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: specializationController,
                        decoration: InputDecoration(
                          labelText: 'Specialization (Optional)',
                          labelStyle: TextStyle(color: kMutedForeground),
                          hintText: 'e.g. Engine, Electrical, Bodywork',
                          hintStyle: TextStyle(color: kMutedForeground.withOpacity(0.5)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isSaving = true;
                            });
                            try {
                              final name = nameController.text.trim();
                              var initials = initialsController.text.trim();
                              if (initials.isEmpty) {
                                initials = deriveInitials(name);
                              }
                              final phone = phoneController.text.trim();
                              final specialization = specializationController.text.trim();

                              final repo = ref.read(mechanicRepositoryProvider);
                              if (isEdit) {
                                final updated = mechanic.copyWith(
                                  name: name,
                                  initials: initials,
                                  phone: phone,
                                  specialization: specialization,
                                );
                                await repo.updateMechanic(updated);
                              } else {
                                final newMech = Mechanic(
                                  name: name,
                                  initials: initials,
                                  phone: phone,
                                  specialization: specialization,
                                  createdAt: DateTime.now(),
                                );
                                await repo.createMechanic(newMech);
                              }
                              ref.invalidate(mechanicListProvider);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to save mechanic: $e')),
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

  void _showDeleteConfirmation(BuildContext context, Mechanic mechanic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Mechanic',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground),
        ),
        content: Text(
          'Are you sure you want to delete ${mechanic.name}?',
          style: TextStyle(color: kForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kMutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ref.read(mechanicRepositoryProvider).deleteMechanic(mechanic.id!);
              ref.invalidate(mechanicListProvider);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mechanicsAsync = ref.watch(mechanicListProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kCard,
        elevation: 0,
        title: Text(
          'Manage Mechanics',
          style: TextStyle(fontWeight: FontWeight.w800, color: kForeground, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: kPrimary),
            onPressed: () => _showAddEditMechanicDialog(context),
          ),
        ],
      ),
      body: mechanicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: kRed)),
        ),
        data: (mechanics) {
          if (mechanics.isEmpty) {
            return EmptyStateView(
              icon: Icons.engineering_outlined,
              title: 'No Mechanics Found',
              description: 'Add mechanics to assign them to job cards.',
              ctaLabel: 'Add Mechanic',
              onCtaPressed: () => _showAddEditMechanicDialog(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: mechanics.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${mechanics.length} mechanics',
                    style: TextStyle(
                      fontSize: 12,
                      color: kMutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              final mechanic = mechanics[i - 1];
              final initials = mechanic.initials.trim().isNotEmpty
                  ? mechanic.initials.trim().toUpperCase()
                  : deriveInitials(mechanic.name);
              final avatar = initials.isNotEmpty ? initials : '?';

              return GarageCard(
                child: Row(
                  children: [
                    AvatarWidget(initials: avatar),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mechanic.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: kForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (mechanic.phone.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 11,
                                  color: kMutedForeground,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  mechanic.phone,
                                  style: TextStyle(fontSize: 12, color: kMutedForeground),
                                ),
                              ],
                            ),
                          if (mechanic.specialization.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                mechanic.specialization,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: kMutedForeground, size: 20),
                      onPressed: () => _showAddEditMechanicDialog(context, mechanic),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: kRed, size: 20),
                      onPressed: () => _showDeleteConfirmation(context, mechanic),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditMechanicDialog(context),
        backgroundColor: kPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
