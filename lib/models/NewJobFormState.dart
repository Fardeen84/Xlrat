import 'CustomerModelas.dart';

class NewJobFormState {
  final int step;
  final Customer? customer;
  final String selectedVehicle;
  final String complaint;
  final String mechanic;

  const NewJobFormState({
    this.step = 1,
    this.customer,
    this.selectedVehicle = '',
    this.complaint = '',
    this.mechanic = '',
  });

  NewJobFormState copyWith({
    int? step,
    Customer? customer,
    String? selectedVehicle,
    String? complaint,
    String? mechanic,
  }) {
    return NewJobFormState(
      step: step ?? this.step,
      customer: customer ?? this.customer,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      complaint: complaint ?? this.complaint,
      mechanic: mechanic ?? this.mechanic,
    );
  }
}