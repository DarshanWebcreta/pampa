import 'package:get_storage/get_storage.dart';

class StorageManager {
  StorageManager._();
  static void saveData(String key, dynamic value) {
    GetStorage box = GetStorage();
    box.write(key, value);
  }

  static dynamic readData(String key) {
    GetStorage box = GetStorage();
    return box.read(key);
  }

  static void deleteData(String key) {
    GetStorage box = GetStorage();
    box.remove(key);
  }

  static void deleteAllData() {
    GetStorage box = GetStorage();
    box.erase();
  }
}
