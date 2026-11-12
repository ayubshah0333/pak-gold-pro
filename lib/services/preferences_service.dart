import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_record.dart';

class PreferencesService extends ChangeNotifier {
  static const String _keyCurrency = 'pref_currency';
  static const String _keyDefaultRate = 'pref_default_rate';
  static const String _keyDefaultTax = 'pref_default_tax';
  static const String _keyDefaultMaking = 'pref_default_making';
  static const String _keyDefaultUnit = 'pref_default_unit';
  static const String _keyCalculationCount = 'pref_calc_count';
  static const String _keyHistory = 'pref_history_records';

  // Sarafa Storage Keys
  static const String keySarafaRate24kTola = 'sarafa_rate_24k_tola';
  static const String keySarafaLastUpdated = 'sarafa_last_updated';
  static const String keySarafaMarketCity = 'sarafa_market_city';
  static const String keyShopName = 'pref_shop_name';
  static const String keyShopContact = 'pref_shop_contact';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // Currency & Defaults (Pakistani Gold Market defaults)
  String get currency => _prefs.getString(_keyCurrency) ?? 'Rs.';
  double get defaultRate {
    final val = _prefs.getDouble(_keyDefaultRate);
    if (val == null || val < 30000.0) {
      return 36755.0;
    }
    return val;
  }
  double get defaultTax => _prefs.getDouble(_keyDefaultTax) ?? 0.0;
  double get defaultMaking => _prefs.getDouble(_keyDefaultMaking) ?? 1500.0;
  String get defaultUnit => _prefs.getString(_keyDefaultUnit) ?? 'g';
  int get calculationCount => _prefs.getInt(_keyCalculationCount) ?? 0;

  // Sarafa Market Rates
  double get sarafaRate24kTola {
    final val = _prefs.getDouble(keySarafaRate24kTola);
    if (val == null || val == 278500.0 || val == 285000.0) {
      return 428700.0;
    }
    return val;
  }
  String get sarafaMarketCity => _prefs.getString(keySarafaMarketCity) ?? 'Karachi / Lahore';
  String get sarafaLastUpdated {
    final saved = _prefs.getString(keySarafaLastUpdated);
    if (saved != null && saved.isNotEmpty) return saved;
    final now = DateTime.now();
    return DateFormat('dd MMM yyyy, hh:mm a').format(now);
  }

  // Derived Sarafa calculations
  double get sarafaRate22kTola => (sarafaRate24kTola * 22.0) / 24.0;
  double get sarafaRate24k10g => (sarafaRate24kTola / 11.6638038) * 10.0;
  double get sarafaRate22k10g => (sarafaRate22kTola / 11.6638038) * 10.0;
  double get sarafaRate24kPerGram => sarafaRate24kTola / 11.6638038;

  Future<void> updateSarafaRates({
    required double rate24kTola,
    String? city,
  }) async {
    await _prefs.setDouble(keySarafaRate24kTola, rate24kTola);
    if (city != null) {
      await _prefs.setString(keySarafaMarketCity, city);
    }
    final nowStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    await _prefs.setString(keySarafaLastUpdated, nowStr);
    // Also keep defaultRate aligned (rate per gram)
    await _prefs.setDouble(_keyDefaultRate, rate24kTola / 11.6638038);
    notifyListeners();
  }

  // Jeweller / Shop Profile
  String get shopName => _prefs.getString(keyShopName) ?? '';
  String get shopContact => _prefs.getString(keyShopContact) ?? '';

  Future<void> updateShopProfile({required String name, String? contact}) async {
    await _prefs.setString(keyShopName, name.trim());
    if (contact != null) {
      await _prefs.setString(keyShopContact, contact.trim());
    }
    notifyListeners();
  }

  List<CalculationRecord> get history {
    final list = _prefs.getStringList(_keyHistory) ?? [];
    return list
        .map((item) {
          try {
            return CalculationRecord.fromJson(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<CalculationRecord>()
        .toList()
        .reversed
        .toList();
  }

  // Setters
  Future<void> setCurrency(String value) async {
    await _prefs.setString(_keyCurrency, value);
    notifyListeners();
  }

  Future<void> setDefaultRate(double value) async {
    await _prefs.setDouble(_keyDefaultRate, value);
    notifyListeners();
  }

  Future<void> setDefaultTax(double value) async {
    await _prefs.setDouble(_keyDefaultTax, value);
    notifyListeners();
  }

  Future<void> setDefaultMaking(double value) async {
    await _prefs.setDouble(_keyDefaultMaking, value);
    notifyListeners();
  }

  Future<void> setDefaultUnit(String value) async {
    await _prefs.setString(_keyDefaultUnit, value);
    notifyListeners();
  }

  Future<int> incrementCalculationCount() async {
    final newCount = calculationCount + 1;
    await _prefs.setInt(_keyCalculationCount, newCount);
    return newCount;
  }

  Future<void> addHistoryRecord(CalculationRecord record) async {
    final currentList = _prefs.getStringList(_keyHistory) ?? [];
    currentList.add(record.toJson());
    // Keep max 150 entries
    if (currentList.length > 150) {
      currentList.removeAt(0);
    }
    await _prefs.setStringList(_keyHistory, currentList);
    notifyListeners();
  }

  Future<void> deleteHistoryRecord(String id) async {
    final currentList = _prefs.getStringList(_keyHistory) ?? [];
    currentList.removeWhere((item) {
      try {
        final decoded = CalculationRecord.fromJson(item);
        return decoded.id == id;
      } catch (_) {
        return false;
      }
    });
    await _prefs.setStringList(_keyHistory, currentList);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_keyHistory);
    notifyListeners();
  }
}
