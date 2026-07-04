

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ─── Database singleton ───────────────────────────────────────────────────────

final billingDatabaseProvider = Provider<BillingDatabase>(
      (ref) => BillingDatabase.instance,
);

final Provider<ReminderService> reminderServiceProvider = Provider<ReminderService>((ref) {
  final billingRepo = ref.watch(billingRepositoryProvider);
  return ReminderService(billingRepo);
});

// ─── repository providers ─────────────────────────────────────────────────────

final customerRepositoryProvider = Provider<CustomerRepository>(
      (ref) => CustomerRepository(ref.watch(billingDatabaseProvider)),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
      (ref) => VehicleRepository(ref.watch(billingDatabaseProvider)),
);

final Provider<BillingRepository> billingRepositoryProvider = Provider<BillingRepository>(
      (ref) => BillingRepository(
        ref.watch(billingDatabaseProvider),
        onInvoiceCreated: (invoice) {
          try {
            ref.read(reminderServiceProvider).scheduleReminderForInvoice(invoice);
          } catch (e) {
            print('Failed to trigger reminder callback: $e');
          }
          try {
            ref.read(cloudSyncServiceProvider).pushPendingInvoices();
          } catch (e) {
            print('Failed to trigger pushPendingInvoices callback: $e');
          }
        },
      ),
);

// ─── Customer providers ───────────────────────────────────────────────────────

final customerListProvider =
FutureProvider.autoDispose<List<BillingCustomer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomers();
});

final customerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final filteredBillingCustomersProvider =
FutureProvider.autoDispose<List<BillingCustomer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchProvider);
  return repo.searchCustomers(query);
});

final customerByIdProvider =
FutureProvider.autoDispose.family<BillingCustomer?, int>((ref, id) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomer(id);
});

final selectedCustomerProvider = StateProvider<BillingCustomer?>((ref) => null);

final customerCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final list = await ref.watch(customerListProvider.future);
  return list.length;
});

// ─── Vehicle providers ────────────────────────────────────────────────────────

final vehiclesForCustomerProvider =
FutureProvider.autoDispose.family<List<BillingVehicle>, int>(
      (ref, customerId) {
    final repo = ref.watch(vehicleRepositoryProvider);
    return repo.getVehiclesForCustomer(customerId);
  },
);

final allVehiclesProvider =
FutureProvider.autoDispose<List<BillingVehicle>>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getAllVehicles();
});

// ─── Invoice list providers ───────────────────────────────────────────────────

final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');
final invoiceStatusFilterProvider = StateProvider<PaymentStatus?>((ref) => null);

final invoiceListProvider = FutureProvider.autoDispose<List<Invoice>>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  final query = ref.watch(invoiceSearchQueryProvider);
  final status = ref.watch(invoiceStatusFilterProvider);
  if (query.isNotEmpty) return repo.searchInvoices(query);
  if (status != null) return repo.getInvoicesByStatus(status);
  return repo.getInvoices();
});

final reportsInvoicesProvider = FutureProvider.autoDispose<List<Invoice>>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getInvoices();
});

final topCustomersProvider = Provider.autoDispose<AsyncValue<List<(String, double, int, String)>>>((ref) {
  final invoicesAsync = ref.watch(reportsInvoicesProvider);
  return invoicesAsync.whenData((invoices) {
    final Map<int, (String, double, int, String)> customerMap = {};
    for (final inv in invoices) {
      final cust = inv.customer;
      if (cust == null) continue;
      final custId = cust.id ?? 0;
      final current = customerMap[custId];
      if (current == null) {
        final initials = cust.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
        customerMap[custId] = (cust.name, inv.grandTotal, 1, initials.isEmpty ? '?' : initials);
      } else {
        customerMap[custId] = (
          current.$1,
          current.$2 + inv.grandTotal,
          current.$3 + 1,
          current.$4,
        );
      }
    }
    final list = customerMap.values.toList();
    list.sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(4).toList();
  });
});

final topPartsProvider = Provider.autoDispose<AsyncValue<List<(String, double, double)>>>((ref) {
  final invoicesAsync = ref.watch(reportsInvoicesProvider);
  return invoicesAsync.whenData((invoices) {
    final Map<String, (double, double)> partsMap = {};
    for (final inv in invoices) {
      if (inv.items == null) continue;
      for (final item in inv.items!) {
        final name = item.itemName;
        final current = partsMap[name];
        if (current == null) {
          partsMap[name] = (item.quantity, item.total);
        } else {
          partsMap[name] = (current.$1 + item.quantity, current.$2 + item.total);
        }
      }
    }
    final list = partsMap.entries.map((e) => (e.key, e.value.$1, e.value.$2)).toList();
    list.sort((a, b) => b.$3.compareTo(a.$3));
    return list.take(4).toList();
  });
});

final invoiceDetailProvider =
FutureProvider.autoDispose.family<Invoice?, int>((ref, id) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getInvoice(id);
});

final invoicesByCustomerProvider =
FutureProvider.autoDispose.family<List<Invoice>, int>((ref, customerId) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getInvoicesByCustomer(customerId);
});

final todaySummaryProvider =
FutureProvider.autoDispose<({double total, int count})>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getTodaySummary();
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
    state = state.copyWith(discount: discount);
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
    final grandTotal = Invoice.calculateGrandTotal(
      subTotal: subTotal,
      discount: state.discount,
      gst: gst,
    );
    state = state.copyWith(subTotal: subTotal, gst: gst, grandTotal: grandTotal);
  }
}

final invoiceDraftProvider =
NotifierProvider<InvoiceDraftNotifier, InvoiceDraft>(
  InvoiceDraftNotifier.new,
);

// ─── InvoiceDraft value object ────────────────────────────────────────────────

class InvoiceDraft {
  final int? invoiceId;
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
    this.gstPercent = 18,
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
    int? invoiceId,
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