import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';
import '../repository/JobRepository.dart';
import 'profile_provider.dart';
import 'billing_providers.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(
    garageId: ref.watch(profileProvider).garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to update job card. Please check your internet connection.",
  );
});


class JobsState {
  final List<Job> jobs;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;

  JobsState({
    required this.jobs,
    required this.isLoading,
    required this.isLoadMore,
    required this.hasMore,
    this.lastDoc,
    this.error,
  });

  factory JobsState.initial() => JobsState(
    jobs: [],
    isLoading: true,
    isLoadMore: false,
    hasMore: true,
  );

  JobsState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
  }) => JobsState(
    jobs: jobs ?? this.jobs,
    isLoading: isLoading ?? this.isLoading,
    isLoadMore: isLoadMore ?? this.isLoadMore,
    hasMore: hasMore ?? this.hasMore,
    lastDoc: lastDoc ?? this.lastDoc,
    error: error,
  );
}

class JobsListNotifier extends StateNotifier<JobsState> {
  final JobRepository _repo;

  JobsListNotifier(this._repo) : super(JobsState.initial()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getJobsPaginated(limit: 50);
      // Guard: the widget watching this notifier may have gone away while we
      // were awaiting Firestore (autoDispose can tear this notifier down
      // mid-flight). Setting `state` after dispose throws, so bail out.
      if (!mounted) return;
      state = state.copyWith(
        jobs: res.items,
        isLoading: false,
        hasMore: res.hasMore,
        lastDoc: res.lastDoc,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadMore || !state.hasMore) return;
    state = state.copyWith(isLoadMore: true);
    try {
      final res = await _repo.getJobsPaginated(limit: 50, startAfter: state.lastDoc);
      if (!mounted) return;
      state = state.copyWith(
        jobs: [...state.jobs, ...res.items],
        isLoadMore: false,
        hasMore: res.hasMore,
        lastDoc: res.lastDoc,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadMore: false, error: e.toString());
    }
  }
}

final jobsListStateProvider = StateNotifierProvider.autoDispose<JobsListNotifier, JobsState>((ref) {
  final repo = ref.watch(jobRepositoryProvider);
  return JobsListNotifier(repo);
});

final jobsProvider = Provider.autoDispose<AsyncValue<List<Job>>>((ref) {
  final state = ref.watch(jobsListStateProvider);
  if (state.isLoading) return const AsyncValue.loading();
  if (state.error != null) return AsyncValue.error(state.error!, StackTrace.current);
  return AsyncValue.data(state.jobs);
});

final jobByIdProvider = FutureProvider.autoDispose.family<Job?, String>((ref, id) {
  final repo = ref.watch(jobRepositoryProvider);
  return repo.getJob(id);
});

final selectedJobProvider = StateProvider<Job?>((ref) => null);

final jobFilterProvider = StateProvider<String>((ref) => 'all');

final filteredJobsProvider = Provider.autoDispose<List<Job>>((ref) {
  final jobs = ref.watch(jobsProvider).value ?? [];
  final filter = ref.watch(jobFilterProvider);
  if (filter == 'all') return jobs;
  return jobs.where((j) => j.status == filter).toList();
});