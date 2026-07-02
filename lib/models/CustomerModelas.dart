// lib/models/models.dart
import 'AppNotification.dart';
import 'InventoryItem.dart';
import 'RevenueData.dart';
import 'job.dart';

class Customer {
  final int id;
  final String name;
  final String phone;
  final int vehicles;
  final String lastVisit;
  final String avatar;
  final int totalSpent;
  final int pending;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicles,
    required this.lastVisit,
    required this.avatar,
    required this.totalSpent,
    required this.pending,
  });
}











// ─── Mock Data ────────────────────────────────────────────────────────────────

const List<RevenueData> revenueData = [
  RevenueData(day: 'Mon', revenue: 12400, jobs: 8),
  RevenueData(day: 'Tue', revenue: 18200, jobs: 12),
  RevenueData(day: 'Wed', revenue: 9800, jobs: 6),
  RevenueData(day: 'Thu', revenue: 22500, jobs: 15),
  RevenueData(day: 'Fri', revenue: 31000, jobs: 19),
  RevenueData(day: 'Sat', revenue: 28700, jobs: 17),
  RevenueData(day: 'Sun', revenue: 14100, jobs: 9),
];

const List<Customer> mockCustomers = [
  Customer(id: 1, name: 'Rajesh Kumar', phone: '9876543210', vehicles: 2, lastVisit: 'Today', avatar: 'RK', totalSpent: 48500, pending: 0),
  Customer(id: 2, name: 'Priya Sharma', phone: '9812345678', vehicles: 1, lastVisit: 'Yesterday', avatar: 'PS', totalSpent: 23200, pending: 3200),
  Customer(id: 3, name: 'Mohammed Irfan', phone: '9988776655', vehicles: 3, lastVisit: '2 days ago', avatar: 'MI', totalSpent: 87600, pending: 0),
  Customer(id: 4, name: 'Sunita Patel', phone: '9765432109', vehicles: 1, lastVisit: '1 week ago', avatar: 'SP', totalSpent: 15800, pending: 0),
  Customer(id: 5, name: 'Arun Nair', phone: '9654321098', vehicles: 2, lastVisit: '3 days ago', avatar: 'AN', totalSpent: 62100, pending: 8700),
  Customer(id: 6, name: 'Deepika Reddy', phone: '9543210987', vehicles: 1, lastVisit: '2 weeks ago', avatar: 'DR', totalSpent: 9400, pending: 0),
];

const List<Job> mockJobs = [
  Job(id: 'JC-2024-0156', customer: 'Rajesh Kumar', vehicle: 'MH12 AB 1234', vehicleType: 'car', brand: 'Maruti Swift', complaint: 'Engine noise, oil leak', mechanic: 'Suresh K.', status: 'in-progress', date: '23 Jun 2024', amount: 8500),
  Job(id: 'JC-2024-0155', customer: 'Priya Sharma', vehicle: 'MH12 CD 5678', vehicleType: 'bike', brand: 'Honda Activa', complaint: 'Brake service, tyre change', mechanic: 'Ramesh V.', status: 'pending', date: '23 Jun 2024', amount: 3200),
  Job(id: 'JC-2024-0154', customer: 'Mohammed Irfan', vehicle: 'MH14 EF 9012', vehicleType: 'car', brand: 'Toyota Innova', complaint: 'AC not working, full service', mechanic: 'Suresh K.', status: 'completed', date: '22 Jun 2024', amount: 14200),
  Job(id: 'JC-2024-0153', customer: 'Sunita Patel', vehicle: 'MH12 GH 3456', vehicleType: 'bike', brand: 'Bajaj Pulsar', complaint: 'Starting problem', mechanic: 'Kiran M.', status: 'completed', date: '22 Jun 2024', amount: 1800),
  Job(id: 'JC-2024-0152', customer: 'Arun Nair', vehicle: 'MH14 IJ 7890', vehicleType: 'car', brand: 'Hyundai i20', complaint: 'Clutch replacement, wheel alignment', mechanic: 'Ramesh V.', status: 'in-progress', date: '21 Jun 2024', amount: 9800),
];

const List<InventoryItem> mockInventory = [
  InventoryItem(id: 1, name: 'Engine Oil 10W-40 (1L)', category: 'Lubricants', stock: 48, unit: 'bottles', purchase: 380, selling: 520, minStock: 20, sku: 'EO-1040-1L'),
  InventoryItem(id: 2, name: 'Oil Filter – Universal', category: 'Filters', stock: 3, unit: 'pcs', purchase: 85, selling: 150, minStock: 10, sku: 'FLT-OIL-UN'),
  InventoryItem(id: 3, name: 'Air Filter – Maruti Swift', category: 'Filters', stock: 7, unit: 'pcs', purchase: 120, selling: 220, minStock: 5, sku: 'FLT-AIR-SW'),
  InventoryItem(id: 4, name: 'Brake Pad Set – Front', category: 'Brakes', stock: 2, unit: 'sets', purchase: 650, selling: 1100, minStock: 5, sku: 'BRK-PAD-FR'),
  InventoryItem(id: 5, name: 'Spark Plug – Bosch', category: 'Ignition', stock: 24, unit: 'pcs', purchase: 95, selling: 180, minStock: 10, sku: 'SPK-BSH-01'),
  InventoryItem(id: 6, name: 'Coolant – Bluechem (1L)', category: 'Lubricants', stock: 15, unit: 'bottles', purchase: 280, selling: 420, minStock: 8, sku: 'CLT-BLU-1L'),
  InventoryItem(id: 7, name: 'Wiper Blade – 20 inch', category: 'Accessories', stock: 1, unit: 'pcs', purchase: 180, selling: 320, minStock: 5, sku: 'WIP-20IN-01'),
  InventoryItem(id: 8, name: 'Battery – 35Ah', category: 'Electrical', stock: 4, unit: 'pcs', purchase: 3200, selling: 4500, minStock: 3, sku: 'BAT-35AH-01'),
];

const List<AppNotification> mockNotifications = [
  AppNotification(id: 1, type: 'service', title: 'Service Reminder', body: "Rajesh Kumar's Swift is due for service (45,000 km)", time: '10 min ago', read: false),
  AppNotification(id: 2, type: 'stock', title: 'Low Stock Alert', body: 'Brake Pad Set – Front has only 2 units left', time: '1 hour ago', read: false),
  AppNotification(id: 3, type: 'payment', title: 'Pending Payment', body: 'Priya Sharma has an outstanding amount of ₹3,200', time: '3 hours ago', read: false),
  AppNotification(id: 4, type: 'service', title: 'Service Reminder', body: "Mohammed Irfan's Innova is due for service next week", time: 'Yesterday', read: true),
  AppNotification(id: 5, type: 'stock', title: 'Low Stock Alert', body: 'Oil Filter – Universal has only 3 units left', time: 'Yesterday', read: true),
  AppNotification(id: 6, type: 'payment', title: 'Payment Received', body: 'Arun Nair paid ₹9,800 for job JC-2024-0149', time: '2 days ago', read: true),
];