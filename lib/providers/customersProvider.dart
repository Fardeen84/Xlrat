// ─── Customers Provider ───────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/CustomerModelas.dart';

final customersProvider = StateProvider<List<Customer>>((ref) => mockCustomers);

final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

final customerSearchProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final customers = ref.watch(customersProvider);
  final query = ref.watch(customerSearchProvider).toLowerCase();
  if (query.isEmpty) return customers;
  return customers.where((c) =>
  c.name.toLowerCase().contains(query) ||
      c.phone.contains(query)
  ).toList();
});