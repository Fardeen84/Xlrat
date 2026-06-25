
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Local Database/billing_database.dart';
import '../Models/Billing model/BillingCustomer.dart';
import '../Models/Billing model/BillingVehicle.dart';
import '../Models/Billing model/InvoiceItem.dart';
import '../Models/Billing model/invoice.dart';
import '../Repository/BillingRepository.dart';
import '../Repository/CustomerRepository.dart';
import '../Repository/VehicleRepository.dart';


// ─── Database singleton ───────────────────────────────────────────────────────

final billingDatabaseProvider = Provider<BillingDatabase>(
      (ref) => BillingDatabase.instance,
);

// ─── Repository providers ─────────────────────────────────────────────────────

final customerRepositoryProvider = Provider<CustomerRepository>(
      (ref) => CustomerRepository(ref.watch(billingDatabaseProvider)),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
      (ref) => VehicleRepository(ref.watch(billingDatabaseProvider)),
);

final billingRepositoryProvider = Provider<BillingRepository>(
      (ref) => BillingRepository(ref.watch(billingDatabaseProvider)),
);

// ─── Customer providers ───────────────────────────────────────────────────────

/// All customers (reactive — re-fetched on invalidation).
final customerListProvider =
FutureProvider.autoDispose<List<BillingCustomer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomers();
});

/// Search query string for customer list.
final customerSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Filtered customer list driven by [customerSearchProvider].
final filteredBillingCustomersProvider =
FutureProvider.autoDispose<List<BillingCustomer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchProvider);
  return repo.searchCustomers(query);
});

/// Single customer by id (used in detail screen).
final customerByIdProvider =
FutureProvider.autoDispose.family<BillingCustomer?, int>((ref, id) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomer(id);
});

// ─── Vehicle providers ────────────────────────────────────────────────────────

/// Vehicles belonging to a specific customer.
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

/// Search/filter state for invoice list.
final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');
final invoiceStatusFilterProvider =
StateProvider<PaymentStatus?>((ref) => null);

/// Full invoice list with optional search.
final invoiceListProvider = FutureProvider.autoDispose<List<Invoice>>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  final query = ref.watch(invoiceSearchQueryProvider);
  final status = ref.watch(invoiceStatusFilterProvider);

  if (query.isNotEmpty) {
    return repo.searchInvoices(query);
  }
  if (status != null) {
    return repo.getInvoicesByStatus(status);
  }
  return repo.getInvoices();
});

/// Single invoice detail (by id).
final invoiceDetailProvider =
FutureProvider.autoDispose.family<Invoice?, int>((ref, id) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getInvoice(id);
});

/// Today's dashboard summary.
final todaySummaryProvider =
FutureProvider.autoDispose<({double total, int count})>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return repo.getTodaySummary();
});

// ─── Invoice draft state (for CreateInvoice / EditInvoice screens) ────────────

/// Notifier that holds the mutable draft while the user builds an invoice.
class InvoiceDraftNotifier extends Notifier<InvoiceDraft> {
  @override
  InvoiceDraft build() => InvoiceDraft.empty();

  void setCustomer(BillingCustomer customer) {
    state = state.copyWith(customer: customer, vehicle: null);
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
    final grandTotal =
    Invoice.calculateGrandTotal(
      subTotal: subTotal,
      discount: state.discount,
      gst: gst,
    );
    state = state.copyWith(
      subTotal: subTotal,
      gst: gst,
      grandTotal: grandTotal,
    );
  }
}

final invoiceDraftProvider =
NotifierProvider<InvoiceDraftNotifier, InvoiceDraft>(
  InvoiceDraftNotifier.new,
);

// ─── InvoiceDraft value object ────────────────────────────────────────────────

/// Mutable state for building a new or editing an existing invoice.
class InvoiceDraft {
  final int? invoiceId; // null → new invoice
  final String invoiceNumber;
  final BillingCustomer? customer;
  final BillingVehicle? vehicle;
  final DateTime invoiceDate;
  final List<InvoiceItem> items;
  final double subTotal;
  final double discount;
  final double gstPercent; // 0 | 5 | 12 | 18 | 28
  final double gst; // computed
  final double grandTotal; // computed
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

  bool get isValid =>
      customer != null && items.isNotEmpty;

  InvoiceDraft copyWith({
    int? invoiceId,
    String? invoiceNumber,
    BillingCustomer? customer,
    BillingVehicle? vehicle,
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
        customer: customer ?? this.customer,
        vehicle: vehicle ?? this.vehicle,
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
