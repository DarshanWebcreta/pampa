import 'package:flutter/foundation.dart';

class CommonNotifier {
  final loading = ValueNotifier<bool>(false);
  final status = ValueNotifier<String>('pending');

  Future<void> fetchData() async {
    loading.value = true;
    await Future.delayed(Duration(seconds: 1));
    status.value = 'in_progress';
    loading.value = false;
  }

  void dispose() {
    loading.dispose();
    status.dispose();
  }
}
