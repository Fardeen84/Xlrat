import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/CustomerModelas.dart';
import '../models/RevenueData.dart';

final revenueDataProvider = Provider<List<RevenueData>>((ref) => revenueData);