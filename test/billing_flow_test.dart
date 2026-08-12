import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xlrat/local_database/billing_database.dart';
import 'package:xlrat/models/billing_model/invoice.dart';
import 'package:xlrat/models/billing_model/InvoiceItem.dart';
import 'package:xlrat/models/billing_model/BillingCustomer.dart';
import 'package:xlrat/models/billing_model/BillingVehicle.dart';
import 'package:xlrat/models/job.dart';
import 'package:xlrat/providers/billing_providers.dart';
import 'package:xlrat/repository/BillingRepository.dart';
import 'package:xlrat/repository/CustomerRepository.dart';
import 'package:xlrat/repository/VehicleRepository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  // Initialize test binding to resolve WidgetsBinding check
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    final db = await BillingDatabase.instance.database;
    await db.delete('billing_invoice_items');
    await db.delete('billing_invoices');
    await db.delete('billing_vehicles');
    await db.delete('billing_customers');
    await db.delete('mechanics');
    await db.update('invoice_counter', {'last_number': 0}, where: 'id = 1');
  });

  test('Billing edit and hydration flow test', () async {
    final firestore = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        customerRepositoryProvider.overrideWithValue(CustomerRepository(garageId: 'test-garage', firestore: firestore)),
        vehicleRepositoryProvider.overrideWithValue(VehicleRepository(garageId: 'test-garage', firestore: firestore)),
        billingRepositoryProvider.overrideWithValue(BillingRepository(garageId: 'test-garage', firestore: firestore)),
      ],
    );
    final billRepo = container.read(billingRepositoryProvider);

    // 1. Create a customer
    final custRepo = container.read(customerRepositoryProvider);
    var customer = BillingCustomer(
      name: 'Test Customer',
      mobile: '1234567890',
      createdAt: DateTime.now(),
    );
    customer = await custRepo.createCustomer(customer);

    // 2. Create an invoice with items
    final item = InvoiceItem(
      itemName: 'Oil Filter',
      quantity: 1,
      price: 350.0,
      total: 350.0,
      createdAt: DateTime.now(),
    );
    final invoice = Invoice(
      invoiceNumber: 'INV-0001',
      customerId: customer.id!,
      invoiceDate: DateTime.now(),
      subTotal: 350.0,
      grandTotal: 350.0,
      createdAt: DateTime.now(),
    );

    final savedInvoice = await billRepo.createInvoice(invoice, [item]);
    expect(savedInvoice.id, isNotNull);
    expect(savedInvoice.items, hasLength(1));

    // 3. Test getInvoice (hydration)
    final hydratedInvoice = await billRepo.getInvoice(savedInvoice.id!);
    expect(hydratedInvoice, isNotNull);
    expect(hydratedInvoice!.items, hasLength(1));
    expect(hydratedInvoice.items.first.itemName, 'Oil Filter');

    // 4. Test loading into draft and saving again (editing)
    final notifier = container.read(invoiceDraftProvider.notifier);
    notifier.loadForEdit(hydratedInvoice);

    final draft = container.read(invoiceDraftProvider);
    expect(draft.invoiceId, savedInvoice.id);
    expect(draft.invoiceNumber, 'INV-000001');
    expect(draft.items, hasLength(1));

    // Modify the draft (e.g. update item price)
    final updatedItem = draft.items.first.copyWith(price: 400.0, total: 400.0);
    notifier.updateItem(0, updatedItem);

    final updatedDraft = container.read(invoiceDraftProvider);
    expect(updatedDraft.items.first.price, 400.0);

    // Save draft as edit
    final isEditing = updatedDraft.invoiceId != null;
    expect(isEditing, isTrue);

    final editedInvoice = Invoice(
      id: updatedDraft.invoiceId,
      invoiceNumber: updatedDraft.invoiceNumber,
      customerId: customer.id!,
      invoiceDate: updatedDraft.invoiceDate,
      subTotal: updatedDraft.subTotal,
      grandTotal: updatedDraft.grandTotal,
      createdAt: DateTime.now(),
    );

    final savedEdited = await billRepo.updateInvoice(editedInvoice, updatedDraft.items);
    expect(savedEdited.id, savedInvoice.id); // Same ID!
    expect(savedEdited.items, hasLength(1));
    expect(savedEdited.items.first.price, 400.0);

    // Verify database count of invoices remains 1 (no duplicate)
    final allInvoices = await billRepo.getInvoices();
    expect(allInvoices, hasLength(1));
    expect(allInvoices.first.id, savedInvoice.id);
    expect(allInvoices.first.items, hasLength(1));
    expect(allInvoices.first.items.first.price, 400.0);
  });

  test('Billing discount clamp test', () {
    final container = ProviderContainer();
    final notifier = container.read(invoiceDraftProvider.notifier);

    // Initial state subtotal should be 0, so discount clamp limit is 0
    notifier.setDiscount(50.0);
    expect(container.read(invoiceDraftProvider).discount, 0.0);

    // Add item with price 100
    notifier.addItem(InvoiceItem(
      itemName: 'Oil Filter',
      quantity: 1,
      price: 100.0,
      total: 100.0,
      createdAt: DateTime.now(),
    ));

    // Subtotal = 100, gstPercent = 0. So max allowed discount is 100.
    // Try setting discount to 150
    notifier.setDiscount(150.0);
    expect(container.read(invoiceDraftProvider).discount, 100.0);
    expect(container.read(invoiceDraftProvider).grandTotal, 0.0);

    // Set valid discount
    notifier.setDiscount(40.0);
    expect(container.read(invoiceDraftProvider).discount, 40.0);
    expect(container.read(invoiceDraftProvider).grandTotal, 60.0);
  });

  test('Job to Invoice prefill test', () async {
    final firestore = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        customerRepositoryProvider.overrideWithValue(CustomerRepository(garageId: 'test-garage', firestore: firestore)),
        vehicleRepositoryProvider.overrideWithValue(VehicleRepository(garageId: 'test-garage', firestore: firestore)),
      ],
    );
    final custRepo = container.read(customerRepositoryProvider);
    final vehRepo = container.read(vehicleRepositoryProvider);

    // Create a matching customer
    var customer = BillingCustomer(
      name: 'John Doe',
      mobile: '9876543210',
      createdAt: DateTime.now(),
    );
    customer = await custRepo.createCustomer(customer);

    // Create a matching vehicle
    var vehicle = BillingVehicle(
      customerId: customer.id!,
      vehicleNumber: 'MH12 AB 9999',
      vehicleBrand: 'Honda',
      vehicleModel: 'Activa',
      createdAt: DateTime.now(),
    );
    vehicle = await vehRepo.createVehicle(vehicle);

    final notifier = container.read(invoiceDraftProvider.notifier);
    notifier.reset();

    // Mock the job resolution logic
    // 1. Job with exact ID matches
    final job = Job(
      id: '1',
      jobNumber: 'JC-2026-0001',
      customer: 'John Doe',
      vehicle: 'MH12 AB 9999',
      vehicleType: 'bike',
      brand: 'Honda Activa',
      complaint: 'Engine oil leak',
      mechanics: const ['Suresh K.'],
      status: 'pending',
      date: '08 Jul 2026',
      amount: 450,
      customerId: customer.id,
      vehicleId: vehicle.id,
    );

    // Resolve Customer
    BillingCustomer? resolvedCustomer;
    if (job.customerId != null) {
      resolvedCustomer = await custRepo.getCustomer(job.customerId!);
    }
    expect(resolvedCustomer, isNotNull);
    expect(resolvedCustomer!.id, customer.id);

    // Resolve Vehicle
    BillingVehicle? resolvedVehicle;
    if (job.vehicleId != null) {
      resolvedVehicle = await vehRepo.getVehicle(job.vehicleId!);
    }
    expect(resolvedVehicle, isNotNull);
    expect(resolvedVehicle!.id, vehicle.id);

    // Prefill Draft
    notifier.setCustomer(resolvedCustomer);
    notifier.setVehicle(resolvedVehicle);

    if (job.amount > 0 || job.complaint.isNotEmpty) {
      notifier.addItem(InvoiceItem(
        itemName: job.complaint.isNotEmpty ? job.complaint : 'Service/Labor Charge',
        quantity: 1,
        price: job.amount.toDouble(),
        total: job.amount.toDouble(),
        createdAt: DateTime.now(),
      ));
    }

    final draft = container.read(invoiceDraftProvider);
    expect(draft.customer, resolvedCustomer);
    expect(draft.vehicle, resolvedVehicle);
    expect(draft.items, hasLength(1));
    expect(draft.items.first.itemName, 'Engine oil leak');
    expect(draft.items.first.price, 450.0);
    expect(draft.subTotal, 450.0);
  });
}
