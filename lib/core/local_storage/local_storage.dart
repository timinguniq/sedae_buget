import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._internal();

  // initialize --------------------//

  /// 2024.02.23 vit
  /// iOS에 FlutterSecureStorage가 키체인에 모든 정보를 저장하기 때문에 앱이 제거되더라도 데이터는 삭제되지 않음.
  /// Refer to : https://stackoverflow.com/a/57937650/576440
  static Future<LocalStorage> getInstance() async {
    final instance = LocalStorage._internal();

    await _isReinstallRun(instance);
    return instance;
  }

  /// 앱 삭제 후 재설치 시 기존 데이터 삭제
  static Future<void> _isReinstallRun(LocalStorage instance) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('first_run') ?? true) {
      await instance._storage.deleteAll();
      await prefs.setBool('first_run', false);
    }
  }

  // storage --------------------//

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<bool> containsKey(String key) {
    return _storage.containsKey(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<Map<String, String>> readAll() {
    return _storage.readAll();
  }

  Future<void> deleteAll() {
    return _storage.deleteAll();
  }
}
