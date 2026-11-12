import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gold_calculator/services/gold_rate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'saved_rate_24k': 282000.0,
      'saved_rate_date': '08 Nov 2026, 04:00 PM',
      'sarafa_rate_24k_tola': 282000.0,
      'sarafa_last_updated': '08 Nov 2026, 04:00 PM',
    });
    GoldRateService.apiUrl = "https://yourdomain.com/api/gold_api.php";
  });

  group('GoldRateService Auto-Update Tests', () {
    test('fetches live Sarafa rate from Web Feed meta and updates cache to 428,700 PKR', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''<!DOCTYPE html><html><head>
          <meta property="og:description" content="Gold rate in Pakistan today is PKR 428,700 per tola for 24K gold." />
          </head><body></body></html>''',
          200,
        );
      });

      final result = await GoldRateService.fetchLiveRate(client: mockClient);

      expect(result['rate'], 428700.0);
      expect(result['isLive'], true);
      expect(result['date'], contains('Sarafa Live'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('saved_rate_24k'), 428700.0);
      expect(prefs.getDouble('sarafa_rate_24k_tola'), 428700.0);
    });

    test('fetches live rate successfully from custom API response and persists to cache', () async {
      GoldRateService.apiUrl = "https://api.pakgoldpro.pk/v1/rates";

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'rate_24k_tola': 428700.0,
            'updated_at': 'Today 05:30 PM (Sarafa Live)',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await GoldRateService.fetchLiveRate(client: mockClient);

      expect(result['rate'], 428700.0);
      expect(result['date'], 'Today 05:30 PM (Sarafa Live)');
      expect(result['isLive'], true);

      // Verify persistent cache was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('saved_rate_24k'), 428700.0);
      expect(prefs.getString('saved_rate_date'), 'Today 05:30 PM (Sarafa Live)');
      expect(prefs.getDouble('sarafa_rate_24k_tola'), 428700.0);
    });

    test('gracefully falls back to cached rate when API returns 500 server error', () async {
      GoldRateService.apiUrl = "https://api.pakgoldpro.pk/v1/rates";

      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final result = await GoldRateService.fetchLiveRate(client: mockClient);

      expect(result['rate'], 282000.0);
      expect(result['isLive'], false);
    });

    test('gracefully falls back to default 428,700 when cache is completely empty and offline', () async {
      SharedPreferences.setMockInitialValues({});
      GoldRateService.apiUrl = "https://yourdomain.com/api/gold_api.php";

      final mockClient = MockClient((request) async {
        throw Exception('Offline network error');
      });

      final result = await GoldRateService.fetchLiveRate(client: mockClient);

      expect(result['rate'], 428700.0);
      expect(result['isLive'], false);
    });
  });
}
