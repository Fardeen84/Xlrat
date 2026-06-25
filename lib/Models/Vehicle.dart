class Vehicle {
  final int id;
  final String number;
  final String brand;
  final String model;
  final String year;
  final String km;
  final String lastService;
  final String type; // 'car' | 'bike'

  const Vehicle({
    required this.id,
    required this.number,
    required this.brand,
    required this.model,
    required this.year,
    required this.km,
    required this.lastService,
    required this.type,
  });
}