import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jewelry_bill.dart';

/// Storage service for saving and retrieving Sarafa Jewelry Bills and Historical Gold Rates.
///
/// Backed by persistent [SharedPreferences].
class SarafaStorage extends ChangeNotifier {
  static const String _keyBills = 'sarafa_jewelry_bills';
  static const String _keyHistoricalRates = 'sarafa_historical_rates';
  static const String _keyCachedRate = 'sarafa_cached_24k_rate';

  final SharedPreferences _prefs;

  SarafaStorage(this._prefs);

  /// Initializes [SarafaStorage] with device's [SharedPreferences].
  static Future<SarafaStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SarafaStorage(prefs);
  }

  // ==========================================
  // JEWELRY BILLS MANAGEMENT
  // ==========================================

  /// Saves a new [JewelryBill] or updates an existing one (matched by ID).
  /// Newest bills are placed first. Max 200 records retained.
  Future<void> saveBill(JewelryBill bill) async {
    final List<String> currentList = _prefs.getStringList(_keyBills) ?? [];

    // Remove if already exists with same ID (update case)
    currentList.removeWhere((item) {
      try {
        final decoded = JewelryBill.fromJson(item);
        return decoded.id == bill.id;
      } catch (_) {
        return false;
      }
    });

    // Insert newest at top
    currentList.insert(0, bill.toJson());

    // Retain maximum 200 bills
    if (currentList.length > 200) {
      currentList.removeRange(200, currentList.length);
    }

    await _prefs.setStringList(_keyBills, currentList);
    notifyListeners();
  }

  /// Retrieves all saved [JewelryBill] records, sorted newest first.
  List<JewelryBill> getBills() {
    final List<String> rawList = _prefs.getStringList(_keyBills) ?? [];
    return rawList
        .map((item) {
          try {
            return JewelryBill.fromJson(item);
          } catch (e) {
            debugPrint('Failed to decode JewelryBill: $e');
            return null;
          }
        })
        .whereType<JewelryBill>()
        .toList();
  }

  /// Deletes a single bill by its [id].
  Future<bool> deleteBill(String id) async {
    final List<String> currentList = _prefs.getStringList(_keyBills) ?? [];
    final int originalLength = currentList.length;

    currentList.removeWhere((item) {
      try {
        final decoded = JewelryBill.fromJson(item);
        return decoded.id == id;
      } catch (_) {
        return false;
      }
    });

    if (currentList.length != originalLength) {
      await _prefs.setStringList(_keyBills, currentList);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Clears all saved jewelry bills.
  Future<void> clearBills() async {
    await _prefs.remove(_keyBills);
    notifyListeners();
  }

  // ==========================================
  // HISTORICAL GOLD RATES MANAGEMENT
  // ==========================================

  /// Saves a snapshot of Sarafa market rates.
  /// Deduplicates by day/ID and keeps up to 365 daily snapshots.
  Future<void> saveRate(GoldRateRecord rate) async {
    final List<String> currentList =
        _prefs.getStringList(_keyHistoricalRates) ?? [];

    // Remove duplicates with exact same ID
    currentList.removeWhere((item) {
      try {
        final decoded = GoldRateRecord.fromJson(item);
        return decoded.id == rate.id;
      } catch (_) {
        return false;
      }
    });

    currentList.insert(0, rate.toJson());

    // Keep up to 365 days of historical rate records
    if (currentList.length > 365) {
      currentList.removeRange(365, currentList.length);
    }

    await _prefs.setStringList(_keyHistoricalRates, currentList);
    await setCached24kRate(rate.rate24kPerTola);
    notifyListeners();
  }

  /// Returns all historical gold rate snapshots, sorted newest first.
  List<GoldRateRecord> getHistoricalRates() {
    final List<String> rawList =
        _prefs.getStringList(_keyHistoricalRates) ?? [];
    return rawList
        .map((item) {
          try {
            return GoldRateRecord.fromJson(item);
          } catch (e) {
            debugPrint('Failed to decode GoldRateRecord: $e');
            return null;
          }
        })
        .whereType<GoldRateRecord>()
        .toList();
  }

  /// Returns the most recently saved gold rate record, or `null` if none exists.
  GoldRateRecord? getLatestRate() {
    final rates = getHistoricalRates();
    return rates.isNotEmpty ? rates.first : null;
  }

  /// Clears all historical gold rate records.
  Future<void> clearRates() async {
    await _prefs.remove(_keyHistoricalRates);
    notifyListeners();
  }

  // ==========================================
  // QUICK CACHED 24K RATE
  // ==========================================

  /// Returns the cached 24K rate per tola in PKR, or `null`.
  double? getCached24kRate() {
    return _prefs.getDouble(_keyCachedRate);
  }

  /// Stores the latest 24K rate per tola for fast startup retrieval.
  Future<void> setCached24kRate(double rate) async {
    await _prefs.setDouble(_keyCachedRate, rate);
    notifyListeners();
  }
}
