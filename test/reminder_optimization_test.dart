import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:xlrat/models/billing_model/BillingCustomer.dart';
import 'package:xlrat/models/billing_model/BillingVehicle.dart';
import 'package:xlrat/models/billing_model/invoice.dart';
import 'package:xlrat/repository/BillingRepository.dart';

class CountingBillingRepository extends BillingRepository {
  int customerReadCount = 0;
  int vehicleReadCount = 0;

  CountingBillingRepository({
    required super.garageId,
    required super.firestore,
  });

  @override
  Future<BillingCustomer?> fetchCustomerForHydration(String customerId) async {
    customerReadCount++;
    return super.fetchCustomerForHydration(customerId);
  }

  @override
  Future<BillingVehicle?> fetchVehicleForHydration(String vehicleId) async {
    vehicleReadCount++;
    return super.fetchVehicleForHydration(vehicleId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BillingRepository.getInvoicesSince filters by date and caches customer/vehicle reads', () async {
    final firestore = FakeFirebaseFirestore();
    final garageId = 'test-garage';
    final repository = CountingBillingRepository(garageId: garageId, firestore: firestore);

    // 1. Populate Customers in Firestore
    final customersCollection = firestore
        .collection('garages')
        .doc(garageId)
        .collection('customers');
    
    await customersCollection.doc('cust_1').set({
      'name': 'Customer One',
      'mobile': '1111111111',
      'created_at': DateTime.now().toIso8601String(),
    });
    await customersCollection.doc('cust_2').set({
      'name': 'Customer Two',
      'mobile': '2222222222',
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Populate Vehicles in Firestore
    final vehiclesCollection = firestore
        .collection('garages')
        .doc(garageId)
        .collection('vehicles');

    await vehiclesCollection.doc('veh_1').set({
      'customer_id': 'cust_1',
      'vehicle_number': 'MH12AA1111',
      'vehicle_brand': 'Brand A',
      'vehicle_model': 'Model A',
      'created_at': DateTime.now().toIso8601String(),
    });
    await vehiclesCollection.doc('veh_2').set({
      'customer_id': 'cust_2',
      'vehicle_number': 'MH12BB2222',
      'vehicle_brand': 'Brand B',
      'vehicle_model': 'Model B',
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. Populate Invoices in Firestore
    final now = DateTime.now();
    final invoicesCollection = firestore
        .collection('garages')
        .doc(garageId)
        .collection('invoices');

    // Invoice 1: 10 days ago (Within 90 days), Customer 1, Vehicle 1
    final date1 = now.subtract(const Duration(days: 10));
    await invoicesCollection.doc('inv_1').set({
      'invoice_number': 'INV-000001',
      'customer_id': 'cust_1',
      'vehicle_id': 'veh_1',
      'invoice_date': date1.toIso8601String(),
      'sub_total': 100.0,
      'grand_total': 100.0,
      'payment_status': 'paid',
      'payment_method': 'cash',
      'notes': '',
      'created_at': date1.toIso8601String(),
      'items': [],
    });

    // Invoice 2: 20 days ago (Within 90 days), Customer 1, Vehicle 1 (Shares same customer/vehicle)
    final date2 = now.subtract(const Duration(days: 20));
    await invoicesCollection.doc('inv_2').set({
      'invoice_number': 'INV-000002',
      'customer_id': 'cust_1',
      'vehicle_id': 'veh_1',
      'invoice_date': date2.toIso8601String(),
      'sub_total': 200.0,
      'grand_total': 200.0,
      'payment_status': 'paid',
      'payment_method': 'cash',
      'notes': '',
      'created_at': date2.toIso8601String(),
      'items': [],
    });

    // Invoice 3: 30 days ago (Within 90 days), Customer 2, Vehicle 2
    final date3 = now.subtract(const Duration(days: 30));
    await invoicesCollection.doc('inv_3').set({
      'invoice_number': 'INV-000003',
      'customer_id': 'cust_2',
      'vehicle_id': 'veh_2',
      'invoice_date': date3.toIso8601String(),
      'sub_total': 300.0,
      'grand_total': 300.0,
      'payment_status': 'paid',
      'payment_method': 'cash',
      'notes': '',
      'created_at': date3.toIso8601String(),
      'items': [],
    });

    // Invoice 4: 100 days ago (Outside 90 days), Customer 1, Vehicle 1
    final date4 = now.subtract(const Duration(days: 100));
    await invoicesCollection.doc('inv_4').set({
      'invoice_number': 'INV-000004',
      'customer_id': 'cust_1',
      'vehicle_id': 'veh_1',
      'invoice_date': date4.toIso8601String(),
      'sub_total': 400.0,
      'grand_total': 400.0,
      'payment_status': 'paid',
      'payment_method': 'cash',
      'notes': '',
      'created_at': date4.toIso8601String(),
      'items': [],
    });

    // 4. Call getInvoicesSince with a 90-day cutoff
    final cutoff = now.subtract(const Duration(days: 90));
    final result = await repository.getInvoicesSince(cutoff);

    // 5. Assertions
    // Only inv_1, inv_2, and inv_3 should be retrieved. inv_4 is outside 90 days.
    expect(result.length, equals(3));
    
    final returnedIds = result.map((inv) => inv.id).toList();
    expect(returnedIds, containsAll(['inv_1', 'inv_2', 'inv_3']));
    expect(returnedIds, isNot(contains('inv_4')));

    // Customer 1 and Customer 2 should each be read exactly once.
    // Vehicle 1 and Vehicle 2 should each be read exactly once.
    expect(repository.customerReadCount, equals(2));
    expect(repository.vehicleReadCount, equals(2));

    // Verify correct sorting (createdAt descending/newest first, i.e., inv_1, then inv_2, then inv_3)
    expect(result[0].id, equals('inv_1'));
    expect(result[1].id, equals('inv_2'));
    expect(result[2].id, equals('inv_3'));
  });
}
