import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_azmi/models/setting_model.dart';
import '../models/user_model.dart';
import '../models/outlet_model.dart';

class Storage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'token';
  static const _userKey = 'user';
  static const _settingKey = 'setting';
  static const _outletKey = 'selected_outlet';
  static const _printerNameKey = 'printer_name';
  static const _printerAddressKey = 'printer_address';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveUser(UserModel user) async {
    final json = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: json);
  }

  static Future<UserModel?> getUser() async {
    final jsonStr = await _storage.read(key: _userKey);
    if (jsonStr == null) return null;
    return UserModel.fromJson(jsonDecode(jsonStr));
  }

  static Future<void> saveSetting(Setting setting) async {
    final json = jsonEncode(setting.toJson());
    await _storage.write(key: _settingKey, value: json);
  }

  static Future<Setting?> getSetting() async {
    final jsonStr = await _storage.read(key: _settingKey);
    if (jsonStr == null) return null;
    return Setting.fromJson(jsonDecode(jsonStr));
  }

  static Future<void> saveOutlet(Outlet outlet) async {
    final json = jsonEncode(outlet.toJson());
    await _storage.write(key: _outletKey, value: json);
  }

  static Future<Outlet?> getOutlet() async {
    final jsonStr = await _storage.read(key: _outletKey);
    if (jsonStr == null) return null;
    return Outlet.fromJson(jsonDecode(jsonStr));
  }

  static Future<void> setPrinter(String name, String address) async {
    await _storage.write(key: _printerNameKey, value: name);
    await _storage.write(key: _printerAddressKey, value: address);
  }

  static Future<Map<String, String>?> getSavedPrinter() async {
    final name = await _storage.read(key: _printerNameKey);
    final address = await _storage.read(key: _printerAddressKey);
    if (name != null && address != null) {
      return {'name': name, 'address': address};
    }
    return null;
  }

  static Future<void> clearSavedPrinter() async {
    await _storage.delete(key: _printerNameKey);
    await _storage.delete(key: _printerAddressKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
