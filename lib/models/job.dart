class Job {
  final String? id;
  final String jobNumber;
  final String customer;
  final String vehicle;
  final String vehicleType;
  final String brand;
  final String complaint;
  final String mechanic;
  final String status; // 'pending' | 'in-progress' | 'completed'
  final String date;
  final int amount;
  final String? customerId;
  final String? vehicleId;
  final String jobType;
  final String itemName;
  final String itemDescription;

  const Job({
    this.id,
    required this.jobNumber,
    required this.customer,
    required this.vehicle,
    required this.vehicleType,
    required this.brand,
    required this.complaint,
    required this.mechanic,
    required this.status,
    required this.date,
    required this.amount,
    this.customerId,
    this.vehicleId,
    this.jobType = 'vehicle',
    this.itemName = '',
    this.itemDescription = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'job_number': jobNumber,
      'customer': customer,
      'vehicle': vehicle,
      'vehicleType': vehicleType,
      'brand': brand,
      'complaint': complaint,
      'mechanic': mechanic,
      'status': status,
      'date': date,
      'amount': amount,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'job_type': jobType,
      'item_name': itemName,
      'item_description': itemDescription,
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        if (value.isEmpty) return null;
        return int.tryParse(value);
      }
      return null;
    }

    return Job(
      id: map['id']?.toString(),
      jobNumber: (map['job_number'] ?? '') as String,
      customer: (map['customer'] ?? '') as String,
      vehicle: (map['vehicle'] ?? '') as String,
      vehicleType: (map['vehicleType'] ?? '') as String,
      brand: (map['brand'] ?? '') as String,
      complaint: (map['complaint'] ?? '') as String,
      mechanic: (map['mechanic'] ?? '') as String,
      status: (map['status'] ?? '') as String,
      date: (map['date'] ?? '') as String,
      amount: parseInt(map['amount']) ?? 0,
      customerId: map['customer_id']?.toString(),
      vehicleId: map['vehicle_id']?.toString(),
      jobType: (map['job_type'] as String?) ?? 'vehicle',
      itemName: (map['item_name'] as String?) ?? '',
      itemDescription: (map['item_description'] as String?) ?? '',
    );
  }

  Job copyWith({
    String? id,
    String? jobNumber,
    String? customer,
    String? vehicle,
    String? vehicleType,
    String? brand,
    String? complaint,
    String? mechanic,
    String? status,
    String? date,
    int? amount,
    String? customerId,
    String? vehicleId,
    String? jobType,
    String? itemName,
    String? itemDescription,
  }) {
    return Job(
      id: id ?? this.id,
      jobNumber: jobNumber ?? this.jobNumber,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      complaint: complaint ?? this.complaint,
      mechanic: mechanic ?? this.mechanic,
      status: status ?? this.status,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      jobType: jobType ?? this.jobType,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
    );
  }
}