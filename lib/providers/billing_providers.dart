import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../local_database/billing_database.dart';
import '../models/billing_model/BillingCustomer.dart';
import '../models/billing_model/BillingVehicle.dart';
import '../models/billing_model/InvoiceItem.dart';
import '../models/billing_model/invoice.dart';
import '../repository/BillingRepository.dart';
import '../repository/CustomerRepository.dart';
import '../repository/VehicleRepository.dart';
import 'ReminderService.dart';
import 'firestoreServiceProvider.dart';
import 'inventoryProvider.dart';
import 'secondHandInventoryProvider.dart';
import 'profile_provider.dart';

// ─── Database singleton ───────────────────────────────────────────────────────

final connectionErrorProvider = StateProvider<String?>((ref) => null);

final billingDatabaseProvider = Provider<BillingDatabase>(
      (ref) => BillingDatabase.instance,
);

final Provider<ReminderService> reminderServiceProvider = Provider<ReminderService>((ref) {
  final billingRepo = ref.watch(billingRepositoryProvider);
  return ReminderService(billingRepo);
});

// ─── repository providers ─────────────────────────────────────────────────────

final customerRepositoryProvider = Provider<CustomerRepository>(
      (ref) => CustomerRepository(
    garageId: ref.watch(profileProvider).garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to update customer. Please check your internet connection.",
  ),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
      (ref) => VehicleRepository(
    garageId: ref.watch(profileProvider).garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to update vehicle. Please check your internet connection.",
  ),
);

final Provider<BillingRepository> billingRepositoryProvider = Provider<BillingRepository>(
      (ref) => BillingRepository(
    garageId: ref.watch(profileProvider).garageId,
    onWriteError: (err) => ref.read(connectionErrorProvider.notifier).state = "Failed to save invoice. Please check your internet connection.",
    onInvoiceCreated: (invoice) async {
      try {
        ref.read(reminderServiceProvider).scheduleReminderForInvoice(invoice);
      } catch (e) {
        print('Failed to trigger reminder callback: $e');
      }
      try {
        await _deductInventoryForInvoice(ref, invoice);
      } catch (e) {
        print('Failed to deduct inventory: $e');
      }
    },
  ),
);

/// Deducts stock for every invoice item linked to an inventory product.
/// Runs once the invoice is actually saved — not while items are being
/// added to the draft.
Future<void> _deductInventoryForInvoice(Ref ref, Invoice invoice) async {
  final items = invoice.items;
  if (items.isEmpty) return;

  for (final item in items) {
    if (item.productId == null) continue;
    if (item.productSource == 'secondhand') {
      final shRepo = ref.read(secondHandInventoryRepositoryProvider);
      final shItem = await shRepo.getItem(item.productId!);
      if (shItem == null) continue;
      final newStock = (shItem.stock - item.quantity.toInt()).clamp(0, 999999).toInt();
      await shRepo.updateStock(item.productId!, newStock);
    } else {
      final invRepo = ref.read(inventoryRepositoryProvider);
      final invItem = await invRepo.getItem(item.productId!);
      if (invItem == null) continue;
      final newStock = (invItem.stock - item.quantity.toInt()).clamp(0, 999999).toInt();
      await invRepo.updateStock(item.productId!, newStock);
    }
  }

  ref.invalidate(inventoryListStateProvider);
  ref.invalidate(secondHandInventoryListStateProvider);
}

// ─── Customer providers ───────────────────────────────────────────────────────

final customerListProvider =
StreamProvider.autoDispose<List<BillingCustomer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.streamCustomers();
});

final customerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final customerByIdProvider =
FutureProvider.autoDispose.family<BillingCustomer?, String>((ref, id) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomer(id);
});

final selectedCustomerProvider = StateProvider<BillingCustomer?>((ref) => null);

// ─── Vehicle providers ────────────────────────────────────────────────────────

final vehiclesForCustomerProvider =
FutureProvider.autoDispose.family<List<BillingVehicle>, String>(
      (ref, customerId) {
    final repo = ref.watch(vehicleRepositoryProvider);
    return repo.getVehiclesForCustomer(customerId);
  },
);

final allVehiclesProvider =
StreamProvider.autoDispose<List<BillingVehicle>>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.streamVehicles();
});

// ─── Invoice list providers ───────────────────────────────────────────────────

final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');
final invoiceStatusFilterProvider = StateProvider<PaymentStatus?>((ref) => null);

class InvoicesState {
  final List<Invoice> invoices;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;

  InvoicesState({
    required this.invoices,
    required this.isLoading,
    required this.isLoadMore,
    required this.hasMore,
    this.lastDoc,
    this.error,
  });

  factory InvoicesState.initial() => InvoicesState(
    invoices: [],
    isLoading: true,
    isLoadMore: false,
    hasMore: true,
  );

  InvoicesState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
  }) => InvoicesState(
    invoices: invoices ?? this.invoices,
    isLoading: isLoading ?? this.isLoading,
    isLoadMore: isLoadMore ?? this.isLoadMore,
    hasMore: hasMore ?? this.hasMore,
    lastDoc: lastDoc ?? this.lastDoc,
    error: error,
  );
}

class InvoicesListNotifier extends StateNotifier<InvoicesState> {
  final BillingRepository _repo;
  final String _query;
  final PaymentStatus? _status;

  InvoicesListNotifier(this._repo, this._query, this._status) : super(InvoicesState.initial()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getInvoicesPaginated(
        limit: 50,
        query: _query,
        status: _status,
      );
      // Guard: this notifier is `.autoDispose` — if the widget watching it
      // went away while we were awaiting Firestore, `mounted` will be false
      // here, and setting `state` on a disposed StateNotifier throws.
      if (!mounted) return;
      state = state.copyWith(
        invoices: res.items,
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
      final res = await _repo.getInvoicesPaginated(
        limit: 50,
        startAfter: state.lastDoc,
        query: _query,
        status: _status,
      );
      if (!mounted) return;
      state = state.copyWith(
        invoices: [...state.invoices, ...res.items],
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

final invoicesListStateProvider = StateNotifierProvider.autoDispose<InvoicesListNotifier, InvoicesState>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  final query = ref.watch(invoiceSearchQueryProvider);
  final status = ref.watch(invoiceStatusFilterProvider);
  return InvoicesListNotifier(repo, query, status);
});

final invoiceListProvider = Provider.autoDispose<AsyncValue<List<Invoice>>>((ref) {
  final state = ref.watch(invoicesListStateProvider);
  if (state.isLoading) return const AsyncValue.loading();
  if (state.error != null) return AsyncValue.error(state.error!, StackTrace.current);
  return AsyncValue.data(state.invoices);
});

// ─── Customer pagination ──────────────────────────────────────────────────────

class CustomersState {
  final List<BillingCustomer> customers;
  final bool isLoading;
  final bool isLoadMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;

  CustomersState({
    required this.customers,
    required this.isLoading,
    required this.isLoadMore,
    required this.hasMore,
    this.lastDoc,
    this.error,
  });

  factory CustomersState.initial() => CustomersState(
    customers: [],
    isLoading: true,
    isLoadMore: false,
    hasMore: true,
  );

  CustomersState copyWith({
    List<BillingCustomer>? customers,
    bool? isLoading,
    bool? isLoadMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
  }) => CustomersState(
    customers: customers ?? this.customers,
    isLoading: isLoading ?? this.isLoading,
    isLoadMore: isLoadMore ?? this.isLoadMore,
    hasMore: hasMore ?? this.hasMore,
    lastDoc: lastDoc ?? this.lastDoc,
    error: error,
  );
}

class CustomersListNotifier extends StateNotifier<CustomersState> {
  final CustomerRepository _repo;
  final String _query;

  CustomersListNotifier(this._repo, this._query) : super(CustomersState.initial()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.getCustomersPaginated(limit: 50, query: _query);
      // Guard: same disposed-notifier race as JobsListNotifier /
      // InvoicesListNotifier — bail out if we've been torn down mid-await.
      if (!mounted) return;
      state = state.copyWith(
        customers: res.items,
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
      final res = await _repo.getCustomersPaginated(
        limit: 50,
        startAfter: state.lastDoc,
        query: _query,
      );
      if (!mounted) return;
      state = state.copyWith(
        customers: [...state.customers, ...res.items],
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

final customerListStateProvider = StateNotifierProvider.autoDispose<CustomersListNotifier, CustomersState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchProvider);
  return CustomersListNotifier(repo, query);
});

final filteredBillingCustomersProvider = FutureProvider.autoDispose<List<BillingCustomer>>((ref) async {
  final state = ref.watch(customerListStateProvider);
  if (state.isLoading) {
    final completer = Completer<List<BillingCustomer>>();
    ref.onDispose(() {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Disposed'));
      }
    });
    return completer.future;
  }
  if (state.error != null) {
    throw state.error!;
  }
  return state.customers;
});

final customerCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerCount();
});

// ─── Reports aggregate stats ──────────────────────────────────────────────────

final reportsDailyStatsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
  final startStr = DateFormat('yyyy-MM-dd').format(sixMonthsAgo);

  return FirebaseFirestore.instance
      .collection('garages')
      .doc(repo.garageId)
      .collection('stats')
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: startStr)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()..['date'] = doc.id).toList());
});

final reportsInvoicesProvider = Provider.autoDispose<AsyncValue<List<Invoice>>>((ref) {
  final statsAsync = ref.watch(reportsDailyStatsProvider);
  return statsAsync.whenData((statsList) {
    final List<Invoice> invoices = [];
    for (final stats in statsList) {
      final dateStr = stats['date'] as String;
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      final count = (stats['invoiceCount'] as num?)?.toInt() ?? 0;
      final revenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;

      if (count > 0) {
        // Distribute revenue evenly or assign to first mock invoice
        final double perInvoice = revenue / count;
        for (int i = 0; i < count; i++) {
          invoices.add(Invoice(
            customerId: '',
            invoiceDate: date,
            subTotal: perInvoice,
            discount: 0,
            gst: 0,
            grandTotal: perInvoice,
            paymentStatus: PaymentStatus.paid,
            paymentMethod: PaymentMethod.cash,
            notes: '',
            items: [],
            createdAt: date,
            invoiceNumber: '',
          ));
        }
      }
    }
    return invoices;
  });
});

final topCustomersProvider = FutureProvider.autoDispose<List<(String, double, int, String)>>((ref) async {
  final statsList = ref.watch(reportsDailyStatsProvider).value ?? [];
  final Map<String, (double, int)> totals = {};
  for (final stats in statsList) {
    final customerTotals = stats['customerTotals'] as Map<dynamic, dynamic>? ?? {};
    customerTotals.forEach((custId, val) {
      final current = totals[custId.toString()];
      final rev = (val['revenue'] as num?)?.toDouble() ?? 0.0;
      final cnt = (val['count'] as num?)?.toInt() ?? 0;
      if (current == null) {
        totals[custId.toString()] = (rev, cnt);
      } else {
        totals[custId.toString()] = (current.$1 + rev, current.$2 + cnt);
      }
    });
  }

  final sortedEntries = totals.entries.toList()
    ..sort((a, b) => b.value.$1.compareTo(a.value.$1));
  final topFourEntries = sortedEntries.take(4).toList();

  final List<(String, double, int, String)> result = [];
  final custRepo = ref.read(customerRepositoryProvider);

  for (final entry in topFourEntries) {
    final customerId = entry.key;
    final rev = entry.value.$1;
    final cnt = entry.value.$2;

    String name = 'Unknown';
    String initials = '?';

    if (customerId.isNotEmpty) {
      final customer = await custRepo.getCustomer(customerId);
      if (customer != null) {
        name = customer.name;
        final parts = customer.name.trim().split(' ');
        initials = parts.map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
        if (initials.isEmpty) initials = '?';
      }
    }
    result.add((name, rev, cnt, initials));
  }
  return result;
});

final topPartsProvider = Provider.autoDispose<AsyncValue<List<(String, double, double)>>>((ref) {
  final statsAsync = ref.watch(reportsDailyStatsProvider);
  return statsAsync.whenData((statsList) {
    final Map<String, (double, double)> partsMap = {};
    for (final stats in statsList) {
      final partTotals = stats['partTotals'] as Map<dynamic, dynamic>? ?? {};
      partTotals.forEach((partName, val) {
        final current = partsMap[partName.toString()];
        final rev = (val['revenue'] as num?)?.toDouble() ?? 0.0;
        final qty = (val['quantity'] as num?)?.toDouble() ?? 0.0;
        if (current == null) {
          partsMap[partName.toString()] = (qty, rev);
        } else {
          partsMap[partName.toString()] = (current.$1 + qty, current.$2 + rev);
        }
      });
    }

    final list = partsMap.entries.map((e) => (e.key, e.value.$1, e.value.$2)).toList();
    list.sort((a, b) => b.$3.compareTo(a.$3));
    return list.take(4).toList();
  });
});

final reportsJobStatusCountsProvider = Provider.autoDispose<AsyncValue<Map<String, int>>>((ref) {
  final statsAsync = ref.watch(reportsDailyStatsProvider);
  return statsAsync.whenData((statsList) {
    int completed = 0;
    int inProgress = 0;
    int pending = 0;
    for (final stats in statsList) {
      completed += (stats['completedJobCount'] as num?)?.toInt() ?? 0;
      inProgress += (stats['inProgressJobCount'] as num?)?.toInt() ?? 0;
      pending += (stats['pendingJobCount'] as num?)?.toInt() ?? 0;
    }
    return {
      'completed': completed,
      'in-progress': inProgress,
      'pending': pending,
    };
  });
});

final todaySummaryProvider = FutureProvider.autoDispose<({double total, int count})>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getTodaySummary();
});

final invoiceDetailProvider =
FutureProvider.autoDispose.family<Invoice?, String>((ref, id) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getInvoice(id);
});

final invoicesByCustomerProvider =
FutureProvider.autoDispose.family<List<Invoice>, String>((ref, customerId) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getInvoicesByCustomer(customerId);
});



// ─── Invoice draft notifier ───────────────────────────────────────────────────

class InvoiceDraftNotifier extends Notifier<InvoiceDraft> {
  @override
  InvoiceDraft build() => InvoiceDraft.empty();

  void setCustomer(BillingCustomer customer) {
    state = state.copyWith(customer: customer, vehicle: null);
  }

  // ── FIX: dummy empty customer set karne ki jagah properly null karo ────────
  void clearCustomer() {
    state = state.copyWith(customer: null, vehicle: null);
  }

  void setVehicle(BillingVehicle? vehicle) {
    state = state.copyWith(vehicle: vehicle);
  }

  void setDate(DateTime date) {
    state = state.copyWith(invoiceDate: date);
  }

  void setDiscount(double discount) {
    final maxAllowed = state.subTotal + state.gst;
    final clamped = discount.clamp(0.0, maxAllowed);
    state = state.copyWith(discount: clamped);
    _recalculate();
  }

  void setGstPercent(double percent) {
    state = state.copyWith(gstPercent: percent);
    _recalculate();
  }

  void setPaymentStatus(PaymentStatus status) {
    state = state.copyWith(paymentStatus: status);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void addItem(InvoiceItem item) {
    state = state.copyWith(items: [...state.items, item]);
    _recalculate();
  }

  void updateItem(int index, InvoiceItem item) {
    final updated = [...state.items];
    updated[index] = item;
    state = state.copyWith(items: updated);
    _recalculate();
  }

  void removeItem(int index) {
    final updated = [...state.items]..removeAt(index);
    state = state.copyWith(items: updated);
    _recalculate();
  }

  void loadForEdit(Invoice invoice) {
    state = InvoiceDraft.fromInvoice(invoice);
  }

  void reset() {
    state = InvoiceDraft.empty();
  }

  void _recalculate() {
    final subTotal =
    state.items.fold<double>(0, (sum, item) => sum + item.total);
    final gst = subTotal * state.gstPercent / 100;
    final maxAllowed = subTotal + gst;
    final clampedDiscount = state.discount.clamp(0.0, maxAllowed);
    final grandTotal = Invoice.calculateGrandTotal(
      subTotal: subTotal,
      discount: clampedDiscount,
      gst: gst,
    );
    state = state.copyWith(
      subTotal: subTotal,
      gst: gst,
      discount: clampedDiscount,
      grandTotal: grandTotal,
    );
  }
}

final invoiceDraftProvider =
NotifierProvider<InvoiceDraftNotifier, InvoiceDraft>(
  InvoiceDraftNotifier.new,
);

// ─── InvoiceDraft value object ────────────────────────────────────────────────

class InvoiceDraft {
  final String? invoiceId;
  final String invoiceNumber;
  final BillingCustomer? customer;
  final BillingVehicle? vehicle;
  final DateTime invoiceDate;
  final List<InvoiceItem> items;
  final double subTotal;
  final double discount;
  final double gstPercent;
  final double gst;
  final double grandTotal;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String notes;

  const InvoiceDraft({
    this.invoiceId,
    this.invoiceNumber = '',
    this.customer,
    this.vehicle,
    required this.invoiceDate,
    this.items = const [],
    this.subTotal = 0,
    this.discount = 0,
    this.gstPercent = 0,
    this.gst = 0,
    this.grandTotal = 0,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod = PaymentMethod.pending,
    this.notes = '',
  });

  factory InvoiceDraft.empty() => InvoiceDraft(invoiceDate: DateTime.now());

  factory InvoiceDraft.fromInvoice(Invoice invoice) {
    final subTotal = invoice.subTotal;
    final gstPercent =
    subTotal > 0 ? (invoice.gst / subTotal * 100).roundToDouble() : 18.0;
    return InvoiceDraft(
      invoiceId: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      customer: invoice.customer,
      vehicle: invoice.vehicle,
      invoiceDate: invoice.invoiceDate,
      items: invoice.items,
      subTotal: invoice.subTotal,
      discount: invoice.discount,
      gstPercent: gstPercent,
      gst: invoice.gst,
      grandTotal: invoice.grandTotal,
      paymentStatus: invoice.paymentStatus,
      paymentMethod: invoice.paymentMethod,
      notes: invoice.notes,
    );
  }

  bool get isValid => customer != null && items.isNotEmpty;

  // ── copyWith — customer/vehicle ko explicitly null karne ke liye sentinel ──
  // Problem: normal copyWith mein `customer: null` pass karo toh purana value
  // rehta hai (null check se). Isliye _Nil sentinel use kiya.
  static const _nil = Object();

  InvoiceDraft copyWith({
    String? invoiceId,
    String? invoiceNumber,
    Object? customer = _nil,   // sentinel — null bhi set ho sake
    Object? vehicle = _nil,    // sentinel — null bhi set ho sake
    DateTime? invoiceDate,
    List<InvoiceItem>? items,
    double? subTotal,
    double? discount,
    double? gstPercent,
    double? gst,
    double? grandTotal,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? notes,
  }) =>
      InvoiceDraft(
        invoiceId: invoiceId ?? this.invoiceId,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        customer: identical(customer, _nil)
            ? this.customer
            : customer as BillingCustomer?,
        vehicle: identical(vehicle, _nil)
            ? this.vehicle
            : vehicle as BillingVehicle?,
        invoiceDate: invoiceDate ?? this.invoiceDate,
        items: items ?? this.items,
        subTotal: subTotal ?? this.subTotal,
        discount: discount ?? this.discount,
        gstPercent: gstPercent ?? this.gstPercent,
        gst: gst ?? this.gst,
        grandTotal: grandTotal ?? this.grandTotal,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        notes: notes ?? this.notes,
      );
}

final dashboardSearchQueryProvider = StateProvider<String>((ref) => '');

final dashboardSearchResultsProvider = FutureProvider<List<Invoice>>((ref) async {
  final query = ref.watch(dashboardSearchQueryProvider);
  if (query.trim().isEmpty) return const [];
  final repo = ref.read(billingRepositoryProvider);
  return repo.searchInvoices(query);
});