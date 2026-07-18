import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:xlrat/repository/CustomerRepository.dart';
import 'package:xlrat/models/billing_model/BillingCustomer.dart';

void main() {
  test('CustomerRepository reads and writes to firestore', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = CustomerRepository(garageId: 'test-garage', firestore: firestore);

    final customer = BillingCustomer(
      name: 'John Doe',
      mobile: '1234567890',
      email: 'john@example.com',
      address: '123 Test St',
      createdAt: DateTime.now(),
    );

    final saved = await repo.createCustomer(customer);
    expect(saved.id, isNotNull);
    expect(saved.name, equals('John Doe'));

    final fetched = await repo.getCustomer(saved.id!);
    expect(fetched, isNotNull);
    expect(fetched!.name, equals('John Doe'));
    expect(fetched.mobile, equals('1234567890'));
  });
}
