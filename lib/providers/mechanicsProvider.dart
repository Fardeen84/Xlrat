import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/Mechanic.dart';
import '../repository/MechanicRepository.dart';
import 'profile_provider.dart';
import 'billing_providers.dart';

final mechanicRepositoryProvider = Provider<MechanicRepository>(
  (ref) => MechanicRepository(
    garageId: ref.watch(profileProvider).garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to update mechanic. Please check your internet connection.",
  ),
);

final mechanicListProvider = StreamProvider.autoDispose<List<Mechanic>>((ref) {
  return ref.watch(mechanicRepositoryProvider).streamMechanics();
});
