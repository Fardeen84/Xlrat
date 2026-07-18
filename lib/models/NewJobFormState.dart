import 'billing_model/BillingCustomer.dart';
import 'billing_model/BillingVehicle.dart';

class NewJobFormState {
  final int step;
  final BillingCustomer? customer;
  final BillingVehicle? vehicle;
  final String selectedVehicle;
  final String complaint;
  final String mechanic;
  final String jobType;

  const NewJobFormState({
    this.step = 1,
    this.customer,
    this.vehicle,
    this.selectedVehicle = '',
    this.complaint = '',
    this.mechanic = '',
    this.jobType = 'vehicle',
  });

  NewJobFormState copyWith({
    int? step,
    BillingCustomer? customer,
    BillingVehicle? vehicle,
    String? selectedVehicle,
    String? complaint,
    String? mechanic,
    String? jobType,
  }) {
    return NewJobFormState(
      step: step ?? this.step,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      complaint: complaint ?? this.complaint,
      mechanic: mechanic ?? this.mechanic,
      jobType: jobType ?? this.jobType,
    );
  }
}