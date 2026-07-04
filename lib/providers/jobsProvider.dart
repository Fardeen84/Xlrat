import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../repository/JobRepository.dart';
import 'billing_providers.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(ref.watch(billingDatabaseProvider));
});

final jobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getAllJobs();
});

final jobByIdProvider = FutureProvider.autoDispose.family<Job?, int>((ref, id) {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getJob(id);
});

final selectedJobProvider = StateProvider<Job?>((ref) => null);

final jobFilterProvider = StateProvider<String>((ref) => 'all');

final filteredJobsProvider = Provider.autoDispose<List<Job>>((ref) {
  final jobsAsync = ref.watch(jobsProvider);
  final jobs = jobsAsync.value ?? [];
  final filter = ref.watch(jobFilterProvider);
  if (filter == 'all') return jobs;
  return jobs.where((j) => j.status == filter).toList();
});