class Job {
  final String id;
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
    required this.id,
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
}