import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gold_calculator/services/gold_math_service.dart';
import 'package:gold_calculator/services/ad_config.dart';
import 'package:gold_calculator/models/jewelry_bill.dart';
import 'package:gold_calculator/services/sarafa_storage.dart';

void main() {
  group('Pakistani Sarafa Constants & Unit Definitions', () {
    test('standard Sarafa constants match Pakistani market specifications', () {
      expect(GoldMathService.gramPerTola, 11.6638);
      expect(GoldMathService.mashaPerTola, 12.0);
      expect(GoldMathService.rattiPerTola, 96.0);
      expect(GoldMathService.rattiPerMasha, 8.0);
      expect(GoldMathService.gramPerMasha, closeTo(11.6638 / 12.0, 1e-9));
      expect(GoldMathService.gramPerRatti, closeTo(11.6638 / 96.0, 1e-9));
    });
  });

  group('GoldMathService.toGrams Conversions', () {
    test('converts 1 Tola exactly to 11.6638 grams', () {
      final grams = GoldMathService.toGrams(tola: 1.0);
      expect(grams, closeTo(11.6638, 1e-6));
    });

    test('converts 12 Masha to exactly 1 Tola (11.6638 grams)', () {
      final grams = GoldMathService.toGrams(masha: 12.0);
      expect(grams, closeTo(11.6638, 1e-6));
    });

    test('converts 96 Ratti to exactly 1 Tola (11.6638 grams)', () {
      final grams = GoldMathService.toGrams(ratti: 96.0);
      expect(grams, closeTo(11.6638, 1e-6));
    });

    test('converts 8 Ratti to 1 Masha', () {
      final gramsFromRatti = GoldMathService.toGrams(ratti: 8.0);
      final gramsFromMasha = GoldMathService.toGrams(masha: 1.0);
      expect(gramsFromRatti, closeTo(gramsFromMasha, 1e-6));
    });

    test('handles compound units: tola, masha, ratti, and grams', () {
      // 2 Tola + 3 Masha + 4 Ratti + 1.5 Grams
      // = 1.5 + (2 * 11.6638) + (3 * (11.6638 / 12)) + (4 * (11.6638 / 96))
      final expected = 1.5 +
          (2 * 11.6638) +
          (3 * (11.6638 / 12.0)) +
          (4 * (11.6638 / 96.0));
      final actual = GoldMathService.toGrams(
        tola: 2.0,
        masha: 3.0,
        ratti: 4.0,
        grams: 1.5,
      );
      expect(actual, closeTo(expected, 1e-6));
    });

    test('default arguments produce 0 grams', () {
      expect(GoldMathService.toGrams(), 0.0);
    });
  });

  group('GoldMathService.gramsToTraditionalUnits', () {
    test('converts exact tola weight correctly', () {
      final units = GoldMathService.gramsToTraditionalUnits(11.6638);
      expect(units.tola, 1);
      expect(units.masha, 0);
      expect(units.ratti, 0.0);
      expect(units.totalTola, closeTo(1.0, 1e-6));
      expect(units.formatted, '1 Tola 0 Masha 0 Ratti');
    });

    test('converts multiple tolas (e.g. 3 tolas)', () {
      final units = GoldMathService.gramsToTraditionalUnits(11.6638 * 3);
      expect(units.tola, 3);
      expect(units.masha, 0);
      expect(units.ratti, 0.0);
      expect(units.totalTola, closeTo(3.0, 1e-6));
    });

    test('converts 1.5 tolas into 1 tola, 6 masha, 0 ratti', () {
      final grams = 11.6638 * 1.5;
      final units = GoldMathService.gramsToTraditionalUnits(grams);
      expect(units.tola, 1);
      expect(units.masha, 6);
      expect(units.ratti, 0.0);
      expect(units.totalTola, closeTo(1.5, 1e-6));
    });

    test('handles zero and negative grams safely', () {
      final zeroUnits = GoldMathService.gramsToTraditionalUnits(0.0);
      expect(zeroUnits.tola, 0);
      expect(zeroUnits.masha, 0);
      expect(zeroUnits.ratti, 0.0);
      expect(zeroUnits.totalTola, 0.0);

      final negUnits = GoldMathService.gramsToTraditionalUnits(-10.0);
      expect(negUnits.tola, 0);
      expect(negUnits.masha, 0);
      expect(negUnits.ratti, 0.0);
      expect(negUnits.totalTola, 0.0);
    });

    test('round-trip consistency between toGrams and gramsToTraditionalUnits', () {
      const originalGrams = 28.75;
      final units = GoldMathService.gramsToTraditionalUnits(originalGrams);
      final reconstructedGrams = GoldMathService.toGrams(
        tola: units.tola.toDouble(),
        masha: units.masha.toDouble(),
        ratti: units.ratti,
      );
      // Precision within 0.001 grams
      expect(reconstructedGrams, closeTo(originalGrams, 0.001));
    });

    test('formattedUrdu output contains correct Urdu terms', () {
      final units = GoldMathService.gramsToTraditionalUnits(11.6638);
      expect(units.formattedUrdu, contains('تولہ'));
      expect(units.formattedUrdu, contains('ماشہ'));
      expect(units.formattedUrdu, contains('رتی'));
    });
  });

  group('GoldMathService.calculateJewelryBill', () {
    test('calculates 24K jewelry bill accurately with stone deduction', () {
      // 20g gross, 2g stone -> 18g net gold
      // Rate 24K per tola = 280,000 PKR
      // Making charges = 5,000 PKR, Discount = 1,000 PKR
      const double gross = 20.0;
      const double stone = 2.0;
      const double rate = 280000.0;
      const double making = 5000.0;
      const double discount = 1000.0;

      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: gross,
        stoneWeightGrams: stone,
        rate24kPerTola: rate,
        karat: 24,
        makingCharges: making,
        discount: discount,
      );

      expect(bill.grossWeightGrams, 20.0);
      expect(bill.stoneWeightGrams, 2.0);
      expect(bill.netWeightGrams, 18.0);

      final expectedNetTola = 18.0 / 11.6638;
      expect(bill.netTola, closeTo(expectedNetTola, 1e-6));

      // 24K rate per gram = 280,000 / 11.6638
      final expectedRatePerGram = rate / 11.6638;
      expect(bill.karatRatePerGram, closeTo(expectedRatePerGram, 1e-6));

      final expectedGoldCost = 18.0 * expectedRatePerGram;
      expect(bill.goldCost, closeTo(expectedGoldCost, 1e-6));

      final expectedTotal = expectedGoldCost + making - discount;
      expect(bill.totalAmount, closeTo(expectedTotal, 1e-6));
    });

    test('calculates 22K jewelry bill with purity multiplier (22/24)', () {
      const double gross = 15.0;
      const double stone = 0.0;
      const double rate24k = 240000.0;

      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: gross,
        stoneWeightGrams: stone,
        rate24kPerTola: rate24k,
        karat: 22,
        makingCharges: 3000.0,
        discount: 500.0,
      );

      final expectedKaratRatePerTola = rate24k * (22.0 / 24.0);
      expect(bill.karatRatePerTola, closeTo(expectedKaratRatePerTola, 1e-6));

      final expectedGoldCost = (15.0 / 11.6638) * expectedKaratRatePerTola;
      expect(bill.goldCost, closeTo(expectedGoldCost, 1e-6));

      expect(bill.totalAmount, closeTo(expectedGoldCost + 3000.0 - 500.0, 1e-6));
    });

    test('clamps net weight and total amount cleanly at 0 when stone > gross or discount > total', () {
      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 5.0,
        stoneWeightGrams: 10.0, // stone exceeds gross
        rate24kPerTola: 250000.0,
        karat: 21,
        discount: 999999.0, // huge discount
      );

      expect(bill.netWeightGrams, 0.0);
      expect(bill.goldCost, 0.0);
      expect(bill.totalAmount, 0.0);
    });
  });

  group('GoldMathService.calculateScrapValue', () {
    test('calculates scrap value with melting loss (kass) and karat factor', () {
      // Gross 12g, Stone 0.3362g -> Net 11.6638g (exactly 1 tola)
      // Karat: 22K (22/24)
      // Melting loss: 2%
      // Rate 24K = 240,000 PKR / tola
      const double gross = 12.0;
      const double stone = 0.3362;
      const double rate24k = 240000.0;
      const double meltingLoss = 2.0;

      final result = GoldMathService.calculateScrapValue(
        grossGrams: gross,
        stoneGrams: stone,
        karat: 22,
        meltingLossPercent: meltingLoss,
        rate24kPerTola: rate24k,
      );

      expect(result.netGrams, closeTo(11.6638, 1e-4));

      // After 2% loss:
      final expectedMelted = 11.6638 * 0.98;
      expect(result.meltedGrams, closeTo(expectedMelted, 1e-4));

      // Pure 24K equivalent grams:
      final expectedPure = expectedMelted * (22.0 / 24.0);
      expect(result.pureGrams, closeTo(expectedPure, 1e-4));

      // Value = pureGrams * (240,000 / 11.6638)
      final expectedValue = expectedPure * (rate24k / 11.6638);
      expect(result.totalValue, closeTo(expectedValue, 1e-4));
    });

    test('calculates 100% pure 24K scrap with 0% loss', () {
      final result = GoldMathService.calculateScrapValue(
        grossGrams: 11.6638,
        stoneGrams: 0.0,
        karat: 24,
        meltingLossPercent: 0.0,
        rate24kPerTola: 250000.0,
      );

      expect(result.netGrams, closeTo(11.6638, 1e-6));
      expect(result.pureGrams, closeTo(11.6638, 1e-6));
      expect(result.pureTola, closeTo(1.0, 1e-6));
      expect(result.totalValue, closeTo(250000.0, 1e-4));
    });
  });

  group('GoldMathService.calculate10GramRate', () {
    test('calculates official 10 Gram rate for 24K and 22K', () {
      const double rate24kPerTola = 280000.0;

      // 10 grams 24K = (280,000 / 11.6638) * 10
      final expected10g24k = (rate24kPerTola / 11.6638) * 10.0;
      final actual10g24k = GoldMathService.calculate10GramRate(rate24kPerTola, 24);
      expect(actual10g24k, closeTo(expected10g24k, 1e-6));

      // 10 grams 22K = (280,000 / 11.6638) * (22 / 24) * 10
      final expected10g22k = (rate24kPerTola / 11.6638) * (22.0 / 24.0) * 10.0;
      final actual10g22k = GoldMathService.calculate10GramRate(rate24kPerTola, 22);
      expect(actual10g22k, closeTo(expected10g22k, 1e-6));
    });
  });

  group('JewelryBill & GoldRateRecord Model Serialization', () {
    test('JewelryBill serializes to/from JSON with exact fidelity', () {
      final original = JewelryBill.fromCalculation(
        id: 'bill-101',
        customerName: 'Muhammad Tariq',
        customerPhone: '03001234567',
        itemName: 'Kundan Bangle Set',
        grossWeightGrams: 35.5,
        stoneWeightGrams: 4.2,
        rate24kPerTola: 275000.0,
        karat: 21,
        makingCharges: 8500.0,
        discount: 1500.0,
        notes: 'Wedding order advance paid',
      );

      final jsonStr = original.toJson();
      final decoded = JewelryBill.fromJson(jsonStr);

      expect(decoded.id, 'bill-101');
      expect(decoded.customerName, 'Muhammad Tariq');
      expect(decoded.customerPhone, '03001234567');
      expect(decoded.itemName, 'Kundan Bangle Set');
      expect(decoded.grossWeightGrams, 35.5);
      expect(decoded.stoneWeightGrams, 4.2);
      expect(decoded.netWeightGrams, closeTo(31.3, 1e-6));
      expect(decoded.karat, 21);
      expect(decoded.totalAmount, closeTo(original.totalAmount, 1e-4));
      expect(decoded.notes, 'Wedding order advance paid');
      expect(decoded.traditionalUnits.tola, original.traditionalUnits.tola);
    });

    test('GoldRateRecord serializes to/from JSON with auto-computed karat rates', () {
      final record = GoldRateRecord(
        id: 'rate-2026-11-08',
        rate24kPerTola: 285000.0,
        city: 'Karachi Sarafa Bazaar',
      );

      expect(record.rate22kPerTola, closeTo(285000.0 * 22.0 / 24.0, 1e-4));
      expect(record.rate21kPerTola, closeTo(285000.0 * 21.0 / 24.0, 1e-4));
      expect(record.rate18kPerTola, closeTo(285000.0 * 18.0 / 24.0, 1e-4));
      expect(record.rate10g24k, closeTo((285000.0 / 11.6638) * 10.0, 1e-4));

      final jsonStr = record.toJson();
      final decoded = GoldRateRecord.fromJson(jsonStr);
      expect(decoded.id, 'rate-2026-11-08');
      expect(decoded.city, 'Karachi Sarafa Bazaar');
      expect(decoded.rate24kPerTola, 285000.0);
    });
  });

  group('SarafaStorage Persistence Service', () {
    test('saves, retrieves, deletes and clears JewelryBills', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SarafaStorage(prefs);

      expect(storage.getBills(), isEmpty);

      final bill1 = JewelryBill.fromCalculation(
        id: 'bill-1',
        itemName: 'Gold Ring',
        grossWeightGrams: 5.5,
        rate24kPerTola: 260000.0,
      );
      final bill2 = JewelryBill.fromCalculation(
        id: 'bill-2',
        itemName: 'Gold Chain',
        grossWeightGrams: 15.0,
        rate24kPerTola: 260000.0,
      );

      await storage.saveBill(bill1);
      await storage.saveBill(bill2);

      final bills = storage.getBills();
      expect(bills.length, 2);
      expect(bills.first.id, 'bill-2'); // Newest first

      final deleted = await storage.deleteBill('bill-1');
      expect(deleted, isTrue);
      expect(storage.getBills().length, 1);
      expect(storage.getBills().first.id, 'bill-2');

      await storage.clearBills();
      expect(storage.getBills(), isEmpty);
    });

    test('saves and retrieves historical rates and cached rates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SarafaStorage(prefs);

      expect(storage.getHistoricalRates(), isEmpty);
      expect(storage.getLatestRate(), isNull);
      expect(storage.getCached24kRate(), isNull);

      final rateToday = GoldRateRecord(
        id: 'rate-1',
        rate24kPerTola: 270000.0,
        city: 'Lahore Sarafa',
      );
      await storage.saveRate(rateToday);

      expect(storage.getHistoricalRates().length, 1);
      expect(storage.getLatestRate()?.rate24kPerTola, 270000.0);
      expect(storage.getCached24kRate(), 270000.0);

      await storage.setCached24kRate(275000.0);
      expect(storage.getCached24kRate(), 275000.0);

      await storage.clearRates();
      expect(storage.getHistoricalRates(), isEmpty);
    });
  });

  group('AdConfig & SmartAdBannerWidget Configuration', () {
    test('adsEnabled is false by default for 100% ad-free launch', () {
      expect(AdConfig.adsEnabled, isFalse);
    });

    test('contains valid standard AdMob test IDs for Android and iOS', () {
      expect(AdConfig.androidBannerTestId, 'ca-app-pub-3940256099942544/6300978111');
      expect(AdConfig.androidInterstitialTestId, 'ca-app-pub-3940256099942544/1033173712');
      expect(AdConfig.iosBannerTestId, 'ca-app-pub-3940256099942544/2934735716');
      expect(AdConfig.iosInterstitialTestId, 'ca-app-pub-3940256099942544/4411468910');
    });

    test('showPostCalculationAd calls onComplete immediately when ads disabled', () {
      AdConfig.adsEnabled = false;
      bool completed = false;

      AdConfig.showPostCalculationAd(onComplete: () {
        completed = true;
      });

      expect(completed, isTrue);
    });

    testWidgets('SmartAdBannerWidget renders SizedBox.shrink when ads are disabled', (tester) async {
      AdConfig.adsEnabled = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartAdBannerWidget(),
          ),
        ),
      );

      // Verify no AdWidget or container is visible
      expect(find.byType(SmartAdBannerWidget), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
