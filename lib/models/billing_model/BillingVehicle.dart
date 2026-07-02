// lib/billing/models/billing_vehicle.dart

/// A vehicle stored in the billing database.
/// One customer may own many vehicles (customerId FK).
class BillingVehicle {
  final int? id;
  final int customerId;
  final String vehicleNumber;
  final String vehicleBrand;
  final String vehicleModel;
  final String fuelType;
  final String engineNumber;
  final String chassisNumber;
  final DateTime createdAt;

  const BillingVehicle({
    this.id,
    required this.customerId,
    required this.vehicleNumber,
    this.vehicleBrand = '',
    this.vehicleModel = '',
    this.fuelType = '',
    this.engineNumber = '',
    this.chassisNumber = '',
    required this.createdAt,
  });

  // ─── DB Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'customer_id': customerId,
    'vehicle_number': vehicleNumber,
    'vehicle_brand': vehicleBrand,
    'vehicle_model': vehicleModel,
    'fuel_type': fuelType,
    'engine_number': engineNumber,
    'chassis_number': chassisNumber,
    'created_at': createdAt.toIso8601String(),
  };

  factory BillingVehicle.fromMap(Map<String, dynamic> map) => BillingVehicle(
    id: map['id'] as int?,
    customerId: map['customer_id'] as int,
    vehicleNumber: map['vehicle_number'] as String,
    vehicleBrand: (map['vehicle_brand'] as String?) ?? '',
    vehicleModel: (map['vehicle_model'] as String?) ?? '',
    fuelType: (map['fuel_type'] as String?) ?? '',
    engineNumber: (map['engine_number'] as String?) ?? '',
    chassisNumber: (map['chassis_number'] as String?) ?? '',
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  // ─── CopyWith ─────────────────────────────────────────────────────────────

  BillingVehicle copyWith({
    int? id,
    int? customerId,
    String? vehicleNumber,
    String? vehicleBrand,
    String? vehicleModel,
    String? fuelType,
    String? engineNumber,
    String? chassisNumber,
    DateTime? createdAt,
  }) =>
      BillingVehicle(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        vehicleBrand: vehicleBrand ?? this.vehicleBrand,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        fuelType: fuelType ?? this.fuelType,
        engineNumber: engineNumber ?? this.engineNumber,
        chassisNumber: chassisNumber ?? this.chassisNumber,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Human-readable summary: "MH12 AB 1234 · Maruti Swift"
  String get displayLabel {
    final parts = [vehicleNumber];
    if (vehicleBrand.isNotEmpty || vehicleModel.isNotEmpty) {
      parts.add('$vehicleBrand $vehicleModel'.trim());
    }
    return parts.join(' · ');
  }

  @override
  String toString() =>
      'BillingVehicle(id: $id, customerId: $customerId, number: $vehicleNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BillingVehicle && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
