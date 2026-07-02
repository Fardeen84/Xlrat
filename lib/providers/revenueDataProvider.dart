import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Models/CustomerModelas.dart';
import '../Models/RevenueData.dart';

final revenueDataProvider = Provider<List<RevenueData>>((ref) => revenueData);