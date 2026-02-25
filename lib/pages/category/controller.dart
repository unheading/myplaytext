import 'package:flutter/foundation.dart';

class CategoryViewController {
  final ValueNotifier<int?> targetTypeId = ValueNotifier<int?>(null);

  void openType(int typeId) {
    targetTypeId.value = typeId;
  }

  void dispose() {
    targetTypeId.dispose();
  }
}

