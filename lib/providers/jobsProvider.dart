// ─── Jobs Provider ────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/CustomerModelas.dart';
import '../models/job.dart';

final jobsProvider = StateProvider<List<Job>>((ref) => mockJobs);

final selectedJobProvider = StateProvider<Job?>((ref) => null);

final jobFilterProvider = StateProvider<String>((ref) => 'all');

final filteredJobsProvider = Provider<List<Job>>((ref) {
  final jobs = ref.watch(jobsProvider);
  final filter = ref.watch(jobFilterProvider);
  if (filter == 'all') return jobs;
  return jobs.where((j) => j.status == filter).toList();
});