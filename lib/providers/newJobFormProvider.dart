import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/NewJobFormState.dart';

final newJobFormProvider = StateProvider<NewJobFormState>((ref) => const NewJobFormState());