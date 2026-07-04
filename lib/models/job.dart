class Job {
  final int? id;
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
    };
  }

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as int?,
      jobNumber: map['job_number'] as String,
      customer: map['customer'] as String,
      vehicle: map['vehicle'] as String,
      vehicleType: map['vehicleType'] as String,
      brand: map['brand'] as String,
      complaint: map['complaint'] as String,
      mechanic: map['mechanic'] as String,
      status: map['status'] as String,
      date: map['date'] as String,
      amount: map['amount'] as int,
    );
  }

  Job copyWith({
    int? id,
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
    );
  }
}