import 'AppNotification.dart';
import 'InventoryItem.dart';
import 'RevenueData.dart';
import 'job.dart';

const List<RevenueData> revenueData = [
  RevenueData(day: 'Mon', revenue: 12400, jobs: 8),
  RevenueData(day: 'Tue', revenue: 18200, jobs: 12),
  RevenueData(day: 'Wed', revenue: 9800, jobs: 6),
  RevenueData(day: 'Thu', revenue: 22500, jobs: 15),
  RevenueData(day: 'Fri', revenue: 31000, jobs: 19),
  RevenueData(day: 'Sat', revenue: 28700, jobs: 17),
  RevenueData(day: 'Sun', revenue: 14100, jobs: 9),
];

const List<Job> mockJobs = [
  Job(id: 1, jobNumber: 'JC-2024-0156', customer: 'Rajesh Kumar', vehicle: 'MH12 AB 1234', vehicleType: 'car', brand: 'Maruti Swift', complaint: 'Engine noise, oil leak', mechanic: 'Suresh K.', status: 'in-progress', date: '23 Jun 2024', amount: 8500),
  Job(id: 2, jobNumber: 'JC-2024-0155', customer: 'Priya Sharma', vehicle: 'MH12 CD 5678', vehicleType: 'bike', brand: 'Honda Activa', complaint: 'Brake service, tyre change', mechanic: 'Ramesh V.', status: 'pending', date: '23 Jun 2024', amount: 3200),
  Job(id: 3, jobNumber: 'JC-2024-0154', customer: 'Mohammed Irfan', vehicle: 'MH14 EF 9012', vehicleType: 'car', brand: 'Toyota Innova', complaint: 'AC not working, full service', mechanic: 'Suresh K.', status: 'completed', date: '22 Jun 2024', amount: 14200),
  Job(id: 4, jobNumber: 'JC-2024-0153', customer: 'Sunita Patel', vehicle: 'MH12 GH 3456', vehicleType: 'bike', brand: 'Bajaj Pulsar', complaint: 'Starting problem', mechanic: 'Kiran M.', status: 'completed', date: '22 Jun 2024', amount: 1800),
  Job(id: 5, jobNumber: 'JC-2024-0152', customer: 'Arun Nair', vehicle: 'MH14 IJ 7890', vehicleType: 'car', brand: 'Hyundai i20', complaint: 'Clutch replacement, wheel alignment', mechanic: 'Ramesh V.', status: 'in-progress', date: '21 Jun 2024', amount: 9800),
];

const List<AppNotification> mockNotifications = [
  AppNotification(id: 1, type: 'service', title: 'Service Reminder', body: "Rajesh Kumar's Swift is due for service (45,000 km)", time: '10 min ago', read: false),
  AppNotification(id: 2, type: 'stock', title: 'Low Stock Alert', body: 'Brake Pad Set – Front has only 2 units left', time: '1 hour ago', read: false),
  AppNotification(id: 3, type: 'payment', title: 'Pending Payment', body: 'Priya Sharma has an outstanding amount of ₹3,200', time: '3 hours ago', read: false),
  AppNotification(id: 4, type: 'service', title: 'Service Reminder', body: "Mohammed Irfan's Innova is due for service next week", time: 'Yesterday', read: true),
  AppNotification(id: 5, type: 'stock', title: 'Low Stock Alert', body: 'Oil Filter – Universal has only 3 units left', time: 'Yesterday', read: true),
  AppNotification(id: 6, type: 'payment', title: 'Payment Received', body: 'Arun Nair paid ₹9,800 for job JC-2024-0149', time: '2 days ago', read: true),
];