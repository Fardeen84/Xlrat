import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Models/NewJobFormState.dart';

final newJobFormProvider = StateProvider<NewJobFormState>((ref) => const NewJobFormState());