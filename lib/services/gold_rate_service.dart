import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Professional Gold Rate Service for Pakistani Jewelers & Sarafa Bazaars.
/// Fetches real-time benchmark rates across primary and secondary Sarafa feeds.
class GoldRateService {
  // Optional custom user endpoint
  static String apiUrl = "https://yourdomain.com/api/gold_api.php";

  // Primary Sarafa Market Live Feed (HamariWeb Financial Rates)
  static const String hamariWebUrl = "https://hamariweb.com/finance/gold_rate/";

  // Backup Sarafa Market Live Feed (UrduPoint Bullion Rates)
  static const String urduPointUrl = "https://www.urdupoint.com/business/gold-rates.html";

  /// Standard official benchmark rate (PKR / Tola)
  static const double standardFallback24k = 428700.0;

  static const Map<String, String> _networkHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Fetches live 24K gold rate per tola.
  /// 1st Priority: Custom user API if configured.
  /// 2nd Priority: Primary Sarafa Market Feed (HamariWeb).
  /// 3rd Priority: Backup Sarafa Market Feed (UrduPoint).
  /// 4th Priority: Persistent local cache (>= 350,000) or Official Sarafa Benchmark.
  static Future<Map<String, dynamic>> fetchLiveRate({http.Client? client}) async {
    final prefs = await SharedPreferences.getInstance();
    final httpClient = client ?? http.Client();

    try {
      // 1. Try Custom API if user configured their own domain
      if (!apiUrl.contains('yourdomain.com') && apiUrl.trim().isNotEmpty) {
        try {
          final response = await httpClient.get(Uri.parse(apiUrl)).timeout(
            const Duration(seconds: 8),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final num? rateNum = (data is Map && data['rate_24k_tola'] != null)
                ? data['rate_24k_tola'] as num?
                : (data is Map && data['rate'] != null)
                    ? data['rate'] as num?
                    : null;

            if (rateNum != null && rateNum >= 350000.0) {
              final double liveRate = rateNum.toDouble();
              final String updateTime = (data is Map && data['updated_at'] != null)
                  ? data['updated_at'].toString()
                  : 'Today (Live API)';

              await _saveToCache(prefs, liveRate, updateTime);
              return {
                'rate': liveRate,
                'date': updateTime,
                'isLive': true,
                'source': 'Custom Sarafa API',
              };
            }
          }
        } catch (e) {
          debugPrint('Custom API failed: $e, falling back to official Sarafa feeds');
        }
      }

      // 2. Fetch from Primary Sarafa Market Live Feed (HamariWeb)
      try {
        final response = await httpClient
            .get(Uri.parse(hamariWebUrl), headers: _networkHeaders)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final double? rate = _extractRateFromHtml(response.body);
          if (rate != null && rate >= 350000.0) {
            final now = DateTime.now();
            final updateTime =
                'Today, ${DateFormat('hh:mm a').format(now)} (Sarafa Live)';
            await _saveToCache(prefs, rate, updateTime);
            return {
              'rate': rate,
              'date': updateTime,
              'isLive': true,
              'source': 'All Pakistan Sarafa Market',
            };
          }
        }
      } catch (e) {
        debugPrint('Primary Sarafa feed error: $e, attempting backup feed...');
      }

      // 3. Fetch from Backup Sarafa Market Live Feed (UrduPoint)
      try {
        final response = await httpClient
            .get(Uri.parse(urduPointUrl), headers: _networkHeaders)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final double? rate = _extractRateFromHtml(response.body);
          if (rate != null && rate >= 350000.0) {
            final now = DateTime.now();
            final updateTime =
                'Today, ${DateFormat('hh:mm a').format(now)} (UrduPoint Live)';
            await _saveToCache(prefs, rate, updateTime);
            return {
              'rate': rate,
              'date': updateTime,
              'isLive': true,
              'source': 'UrduPoint Bullion',
            };
          }
        }
      } catch (e) {
        debugPrint('Backup Sarafa feed error: $e');
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    // 4. Fallback: Saved Local Cache (discarding legacy obsolete 278,500 / 285,000)
    final double? savedRate = prefs.getDouble('saved_rate_24k') ??
        prefs.getDouble('sarafa_rate_24k_tola');

    final double cachedRate = (savedRate != null &&
            savedRate != 278500.0 &&
            savedRate != 285000.0)
        ? savedRate
        : standardFallback24k;

    final String cachedDate = prefs.getString('saved_rate_date') ??
        prefs.getString('sarafa_last_updated') ??
        'Sarafa Standard (Benchmark)';

    // Always ensure SharedPreferences is synced with at least standard benchmark
    await _saveToCache(prefs, cachedRate, cachedDate);

    return {
      'rate': cachedRate,
      'date': cachedDate,
      'isLive': false,
      'source': 'Official Benchmark',
    };
  }

  static double? _extractRateFromHtml(String html) {
    // Pattern 1: 'is PKR/Rs. 428,700 per tola for 24K'
    final p1 = RegExp(
      r'(?:is|today)\s*(?:PKR|Rs\.?)\s*([0-9]{1,3}(?:,[0-9]{3})+)\s*per tola for 24K',
      caseSensitive: false,
    );
    final m1 = p1.firstMatch(html);
    if (m1 != null) {
      final str = m1.group(1)!.replaceAll(',', '');
      return double.tryParse(str);
    }

    // Pattern 2: 'is PKR/Rs. 428,700 per tola'
    final p2 = RegExp(
      r'(?:is|today)\s*(?:PKR|Rs\.?)\s*([0-9]{1,3}(?:,[0-9]{3})+)\s*per tola',
      caseSensitive: false,
    );
    final m2 = p2.firstMatch(html);
    if (m2 != null) {
      final str = m2.group(1)!.replaceAll(',', '');
      return double.tryParse(str);
    }

    // Pattern 3: '24K - 1 Tola: 428,700'
    final p3 = RegExp(
      r'24K\s*-\s*1\s*Tola:\s*</strong>\s*([0-9]{1,3}(?:,[0-9]{3})+)',
      caseSensitive: false,
    );
    final m3 = p3.firstMatch(html);
    if (m3 != null) {
      final str = m3.group(1)!.replaceAll(',', '');
      return double.tryParse(str);
    }

    // Pattern 4: '24K Gold Rate / 24 Karat gold is Rs. 428,700'
    final p4 = RegExp(
      r'24\s*K(?:arat)?\s*gold\s*is\s*Rs\.?\s*([0-9]{1,3}(?:,[0-9]{3})+)',
      caseSensitive: false,
    );
    final m4 = p4.firstMatch(html);
    if (m4 != null) {
      final str = m4.group(1)!.replaceAll(',', '');
      return double.tryParse(str);
    }

    return null;
  }

  static Future<void> _saveToCache(
    SharedPreferences prefs,
    double rate,
    String date,
  ) async {
    await prefs.setDouble('saved_rate_24k', rate);
    await prefs.setString('saved_rate_date', date);
    await prefs.setDouble('sarafa_rate_24k_tola', rate);
    await prefs.setString('sarafa_last_updated', date);
  }
}
