import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/Theme.dart';
import '../models/billing_model/BillingCustomer.dart';
import '../models/billing_model/BillingVehicle.dart';
import '../providers/billing_providers.dart';

class QuickAddSheets {
  static void showAddCustomer(
    BuildContext context,
    WidgetRef ref, {
    required Function(BillingCustomer) onSaved,
  }) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quick Add Customer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kForeground)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kMutedForeground),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                  ),
                  style: const TextStyle(color: kForeground),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mobileCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  ),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: kForeground),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter mobile number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Optional)',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  ),
                  maxLines: 2,
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newCust = BillingCustomer(
                        name: nameCtrl.text.trim(),
                        mobile: mobileCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      final saved = await ref.read(customerRepositoryProvider).createCustomer(newCust);
                      ref.invalidate(customerListProvider);
                      ref.invalidate(filteredBillingCustomersProvider);
                      onSaved(saved);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save & Select Customer'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showAddVehicle(
    BuildContext context,
    WidgetRef ref, {
    required int customerId,
    required Function(BillingVehicle) onSaved,
  }) {
    final numberCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final fuelTypeCtrl = TextEditingController();
    final engineCtrl = TextEditingController();
    final chassisCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quick Add Vehicle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kForeground)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kMutedForeground),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number (e.g. MH12AB1234) *',
                    prefixIcon: Icon(Icons.pin_outlined, size: 18),
                  ),
                  style: const TextStyle(color: kForeground),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter vehicle number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Brand (e.g. Maruti, Honda) *',
                    prefixIcon: Icon(Icons.directions_car_filled_outlined, size: 18),
                  ),
                  style: const TextStyle(color: kForeground),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter brand' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Model (e.g. Swift, City) *',
                    prefixIcon: Icon(Icons.model_training_outlined, size: 18),
                  ),
                  style: const TextStyle(color: kForeground),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter model' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fuelTypeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Type (e.g. Petrol, Diesel, CNG)',
                    prefixIcon: Icon(Icons.local_gas_station_outlined, size: 18),
                  ),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: engineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Engine Number (Optional)',
                    prefixIcon: Icon(Icons.settings_outlined, size: 18),
                  ),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: chassisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Chassis Number (Optional)',
                    prefixIcon: Icon(Icons.tag_rounded, size: 18),
                  ),
                  style: const TextStyle(color: kForeground),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newVehicle = BillingVehicle(
                        customerId: customerId,
                        vehicleNumber: numberCtrl.text.trim().toUpperCase(),
                        vehicleBrand: brandCtrl.text.trim(),
                        vehicleModel: modelCtrl.text.trim(),
                        fuelType: fuelTypeCtrl.text.trim(),
                        engineNumber: engineCtrl.text.trim(),
                        chassisNumber: chassisCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      final saved = await ref.read(vehicleRepositoryProvider).createVehicle(newVehicle);
                      ref.invalidate(vehiclesForCustomerProvider(customerId));
                      ref.invalidate(allVehiclesProvider);
                      onSaved(saved);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save & Select Vehicle'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
