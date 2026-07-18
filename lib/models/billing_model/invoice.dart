// lib/billing/models/invoice.dart


import 'BillingCustomer.dart';
import 'BillingVehicle.dart';
import 'InvoiceItem.dart';

/// Payment status constants — exhaustive enum avoids typo bugs.
enum PaymentStatus {
  paid,
  pending,
  partial;

  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
    }
  }

  static PaymentStatus fromString(String s) {
    switch (s) {
      case 'paid':
        return PaymentStatus.paid;
      case 'partial':
        return PaymentStatus.partial;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Payment method constants.
enum PaymentMethod {
  cash,
  upi,
  card,
  bank,
  pending;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.pending:
        return 'Pending';
    }
  }

  static PaymentMethod fromString(String s) {
    switch (s) {
      case 'cash':
        return PaymentMethod.cash;
      case 'upi':
        return PaymentMethod.upi;
      case 'card':
        return PaymentMethod.card;
      case 'bank':
        return PaymentMethod.bank;
      default:
        return PaymentMethod.pending;
    }
  }
}

// ─── Invoice ──────────────────────────────────────────────────────────────────

class Invoice {
  final String? id;
  final String invoiceNumber;
  final String customerId;
  final String? vehicleId;
  final DateTime invoiceDate;
  final double subTotal;
  final double discount; // absolute ₹ value
  final double gst; // absolute ₹ value
  final double grandTotal;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String notes;
  final DateTime createdAt;

  // ─── Joined / eager-loaded fields (not stored in row) ──────────────────
  // These are populated by the repository when fetching invoice details.
  final BillingCustomer? customer;
  final BillingVehicle? vehicle;
  final List<InvoiceItem> items;

  const Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerId,
    this.vehicleId,
    required this.invoiceDate,
    required this.subTotal,
    this.discount = 0,
    this.gst = 0,
    required this.grandTotal,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod = PaymentMethod.pending,
    this.notes = '',
    required this.createdAt,
    this.customer,
    this.vehicle,
    this.items = const [],
  });

  // ─── Business logic: total calculation ───────────────────────────────────

  /// Recalculates grandTotal from parts — use when building a draft.
  static double calculateGrandTotal({
    required double subTotal,
    required double discount,
    required double gst,
  }) =>
      (subTotal - discount + gst).clamp(0, double.infinity);

  // ─── DB Serialization ────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'invoice_number': invoiceNumber,
    'customer_id': customerId,
    'vehicle_id': vehicleId,
    'invoice_date': invoiceDate.toIso8601String(),
    'sub_total': subTotal,
    'discount': discount,
    'gst': gst,
    'grand_total': grandTotal,
    'payment_status': paymentStatus.name,
    'payment_method': paymentMethod.name,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'items': items.map((item) => item.toMap()).toList(),
  };

  factory Invoice.fromMap(Map<String, dynamic> map) => Invoice(
    id: map['id']?.toString(),
    invoiceNumber: map['invoice_number'] as String? ?? '',
    customerId: map['customer_id']?.toString() ?? '',
    vehicleId: map['vehicle_id']?.toString(),
    invoiceDate: DateTime.parse(map['invoice_date'] as String),
    subTotal: (map['sub_total'] as num).toDouble(),
    discount: (map['discount'] as num?)?.toDouble() ?? 0,
    gst: (map['gst'] as num?)?.toDouble() ?? 0,
    grandTotal: (map['grand_total'] as num).toDouble(),
    paymentStatus:
    PaymentStatus.fromString(map['payment_status'] as String? ?? ''),
    paymentMethod:
    PaymentMethod.fromString(map['payment_method'] as String? ?? ''),
    notes: (map['notes'] as String?) ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
    items: (map['items'] as List?)
        ?.map((item) => InvoiceItem.fromMap(Map<String, dynamic>.from(item)))
        .toList() ?? const [],
  );

  // ─── CopyWith ─────────────────────────────────────────────────────────────

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? vehicleId,
    DateTime? invoiceDate,
    double? subTotal,
    double? discount,
    double? gst,
    double? grandTotal,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? createdAt,
    BillingCustomer? customer,
    BillingVehicle? vehicle,
    List<InvoiceItem>? items,
  }) =>
      Invoice(
        id: id ?? this.id,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        customerId: customerId ?? this.customerId,
        vehicleId: vehicleId ?? this.vehicleId,
        invoiceDate: invoiceDate ?? this.invoiceDate,
        subTotal: subTotal ?? this.subTotal,
        discount: discount ?? this.discount,
        gst: gst ?? this.gst,
        grandTotal: grandTotal ?? this.grandTotal,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        customer: customer ?? this.customer,
        vehicle: vehicle ?? this.vehicle,
        items: items ?? this.items,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Invoice && other.id == id && other.invoiceNumber == invoiceNumber;

  @override
  int get hashCode => Object.hash(id, invoiceNumber);
}
