import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:valkyr/model/models.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final String _passwordsKey = 'encrypted_passwords';

  Future<void> savePasswords(List<PasswordEntry> passwords) async {
    final jsonData = jsonEncode(passwords.map((p) => p.toJson()).toList());
    await _storage.write(key: _passwordsKey, value: jsonData);
  }

  Future<List<PasswordEntry>> getPasswords() async {
    final jsonData = await _storage.read(key: _passwordsKey);
    if (jsonData == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonData);
    return decoded.map((p) => PasswordEntry.fromJson(p)).toList();
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
