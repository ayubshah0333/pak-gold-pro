import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gold_calculator/utils/gold_math.dart';
import 'package:gold_calculator/services/gold_math_service.dart';
import 'package:gold_calculator/models/jewelry_bill.dart';
import 'package:gold_calculator/services/sarafa_storage.dart';
import 'package:gold_calculator/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Pakistani Sarafa Constants & Traditional Unit Conversion Back-Testing', () {
    test('standard Sarafa unit definitions and imperial grain equivalence', () {
      // 1 Tola = 11.6638 grams (or 11.6638038g historical British-Indian standard)
      // 1 Tola = 12 Masha = 96 Ratti = 180 Grains (Imperial Troy grain)
      const double tolaGrams = 11.6638;
      const double tolaGrains = 180.0;
      const double mashaGrains = tolaGrains / 12.0; // 15 grains
      const double rattiGrains = tolaGrains / 96.0; // 1.875 grains
      const double gramPerGrain = tolaGrams / tolaGrains; // ~0.0647988889 g

      expect(GoldMathService.gramPerTola, 11.6638);
      expect(GoldMathService.mashaPerTola, 12.0);
      expect(GoldMathService.rattiPerTola, 96.0);
      expect(GoldMathService.rattiPerMasha, 8.0);

      // Verify grain derivations
      expect(mashaGrains, 15.0);
      expect(rattiGrains, 1.875);
      expect(12 * mashaGrains, 180.0);
      expect(96 * rattiGrains, 180.0);

      // Verify weight of 180 grains equals 1 tola in grams
      expect(180.0 * gramPerGrain, closeTo(11.6638, 1e-9));
      expect(15.0 * gramPerGrain, closeTo(GoldMathService.gramPerMasha, 1e-9));
      expect(1.875 * gramPerGrain, closeTo(GoldMathService.gramPerRatti, 1e-9));

      // Test GoldMath conversion helpers
      expect(GoldMath.convertToGrams(1.0, 'tola'), closeTo(11.6638038, 1e-6));
      expect(GoldMath.convertToGrams(12.0, 'masha'), closeTo(11.6638038, 1e-6));
      expect(GoldMath.convertToGrams(96.0, 'ratti'), closeTo(11.6638038, 1e-6));
      expect(GoldMath.convertToGrams(1.0, 'kg'), 1000.0);
      expect(GoldMath.convertToGrams(1.0, 'pavan'), 8.0);
    });

    test('compound weights conversion to exact grams (e.g. 2 Tola 5 Masha 3.5 Ratti)', () {
      // Scenario A: 2 Tola, 5 Masha, 3.5 Ratti
      // 2 * 11.6638 = 23.3276 g
      // 5 Masha = 5 * (11.6638 / 12) = 4.859916667 g
      // 3.5 Ratti = 3.5 * (11.6638 / 96) = 0.4252427083 g
      // Total = 28.612759375 g
      final gramsA = GoldMathService.toGrams(tola: 2.0, masha: 5.0, ratti: 3.5);
      expect(gramsA, closeTo(28.612759375, 1e-6));

      // Check GoldMath.tmrToGrams gives identical standard
      final goldMathGramsA = GoldMath.tmrToGrams(tola: 2.0, masha: 5.0, ratti: 3.5);
      expect(goldMathGramsA, closeTo(28.612769, 1e-4));

      // Scenario B: Traditional Pakistani Bridal Necklace weight: 4 Tola 8 Masha 2 Ratti
      // 4 * 11.6638 + 8 * (11.6638 / 12) + 2 * (11.6638 / 96)
      // = 46.6552 + 7.7758667 + 0.2429958 = 54.6740625 g
      final gramsB = GoldMathService.toGrams(tola: 4.0, masha: 8.0, ratti: 2.0);
      expect(gramsB, closeTo(54.6740625, 1e-6));

      // Scenario C: Small Gold Ring: 0 Tola 4 Masha 6 Ratti
      // 0 + 4 * (11.6638 / 12) + 6 * (11.6638 / 96) = 3.8879333 + 0.7289875 = 4.6169208 g
      final gramsC = GoldMathService.toGrams(tola: 0.0, masha: 4.0, ratti: 6.0);
      expect(gramsC, closeTo(4.6169208, 1e-6));
    });

    test('high-precision round-trip arithmetic: grams -> TMR -> grams within 0.0001g error bound', () {
      // Extensive test cases representing real Pakistani jeweler weighings
      final List<double> testGramsList = [
        0.05,        // Fine earring stud / nose pin
        0.1215,      // ~1 Ratti
        0.2430,      // ~2 Ratti
        0.9720,      // ~1 Masha
        1.0,         // 1 gram
        2.543,       // Small ring
        5.8319,      // Half tola (6 masha)
        8.724,       // Pendant
        11.6638,     // Exactly 1 tola
        17.4957,     // 1.5 tola
        23.3276,     // Exactly 2 tola
        28.6128,     // 2 tola 5 masha 3.5 ratti
        35.0,        // Heavy bangle
        58.3190,     // Exactly 5 tola
        116.6380,    // 10 tola gold bar (TT bar)
        250.0,       // Quarter kilogram
        500.0,       // Half kilogram
        1166.3800,   // 100 tolas commercial brick
      ];

      for (final originalGrams in testGramsList) {
        // Test with GoldMathService
        final traditionalUnits = GoldMathService.gramsToTraditionalUnits(originalGrams);
        final reconstructedGramsService = GoldMathService.toGrams(
          tola: traditionalUnits.tola.toDouble(),
          masha: traditionalUnits.masha.toDouble(),
          ratti: traditionalUnits.ratti,
        );

        final serviceError = (reconstructedGramsService - originalGrams).abs();
        expect(
          serviceError,
          lessThanOrEqualTo(0.0001),
          reason: 'GoldMathService round-trip failed for $originalGrams g. Got $reconstructedGramsService g (err: $serviceError)',
        );

        // Test with GoldMath.gramsToTMR and GoldMath.tmrToGrams
        final tmr = GoldMath.gramsToTMR(originalGrams);
        final reconstructedGramsMath = GoldMath.tmrToGrams(
          tola: tmr.tola.toDouble(),
          masha: tmr.masha.toDouble(),
          ratti: tmr.ratti,
        );

        final mathError = (reconstructedGramsMath - originalGrams).abs();
        expect(
          mathError,
          lessThanOrEqualTo(0.0001),
          reason: 'GoldMath round-trip failed for $originalGrams g. Got $reconstructedGramsMath g (err: $mathError)',
        );
      }
    });

    test('TMR edge-case rollover: 7.9999 Ratti rolls over to next Masha seamlessly', () {
      // 1 Masha - tiny epsilon = 0.97198365 g
      // When ratti approaches 8, it must gracefully increment masha and reset ratti
      final justUnderMasha = GoldMathService.gramPerMasha - 0.000001;
      final units = GoldMathService.gramsToTraditionalUnits(justUnderMasha);
      expect(units.masha, 1);
      expect(units.ratti, 0.0);

      // 1 Tola - tiny epsilon = 11.6638 - 1e-7
      final justUnderTola = 11.6638 - 0.000001;
      final tolaUnits = GoldMathService.gramsToTraditionalUnits(justUnderTola);
      expect(tolaUnits.tola, 1);
      expect(tolaUnits.masha, 0);
      expect(tolaUnits.ratti, 0.0);
    });
  });

  group('2. Sarafa Market Rate Caching & Karat / 10-Gram Derivations (Karachi, Peshawar, Lahore)', () {
    test('derives 10-gram rates and karat rates for Karachi Sarafa baseline (Rs. 285,000 / Tola)', () {
      const double karachiRate24k = 285000.0;

      // 10g 24K rate = (rate24kTola / 11.6638) * 10
      final double expected10g24k = (karachiRate24k / 11.6638) * 10.0; // ~244,345.75 PKR
      final double calculated10g24k = GoldMathService.calculate10GramRate(karachiRate24k, 24);
      expect(calculated10g24k, closeTo(expected10g24k, 0.01));

      // 22K per tola = 285,000 * 22 / 24 = 261,250 PKR
      const double expected22kTola = (karachiRate24k * 22.0) / 24.0;
      expect(expected22kTola, 261250.0);

      // 10g 22K rate = (22K rate per tola / 11.6638) * 10
      final double expected10g22k = (expected22kTola / 11.6638) * 10.0; // ~223,983.61 PKR
      final double calculated10g22k = GoldMathService.calculate10GramRate(karachiRate24k, 22);
      expect(calculated10g22k, closeTo(expected10g22k, 0.01));

      // 21K per tola = 285,000 * 21 / 24 = 249,375 PKR
      const double expected21kTola = (karachiRate24k * 21.0) / 24.0;
      expect(expected21kTola, 249375.0);
      final double calculated10g21k = GoldMathService.calculate10GramRate(karachiRate24k, 21);
      expect(calculated10g21k, closeTo((expected21kTola / 11.6638) * 10.0, 0.01));

      // 18K per tola = 285,000 * 18 / 24 = 213,750 PKR
      const double expected18kTola = (karachiRate24k * 18.0) / 24.0;
      expect(expected18kTola, 213750.0);
      final double calculated10g18k = GoldMathService.calculate10GramRate(karachiRate24k, 18);
      expect(calculated10g18k, closeTo((expected18kTola / 11.6638) * 10.0, 0.01));
    });

    test('derives rates for Peshawar Sarafa Bazaar rate (Rs. 286,200 / Tola)', () {
      const double peshawarRate24k = 286200.0;
      final record = GoldRateRecord(
        id: 'rate_peshawar_01',
        rate24kPerTola: peshawarRate24k,
        city: 'Peshawar Sarafa Bazaar',
      );

      expect(record.city, 'Peshawar Sarafa Bazaar');
      expect(record.rate24kPerTola, 286200.0);
      expect(record.rate22kPerTola, closeTo(286200.0 * 22 / 24, 0.01));
      expect(record.rate21kPerTola, closeTo(286200.0 * 21 / 24, 0.01));
      expect(record.rate18kPerTola, closeTo(286200.0 * 18 / 24, 0.01));
      expect(record.rate10g24k, closeTo((286200.0 / 11.6638) * 10, 0.01));
      expect(record.rate10g22k, closeTo(((286200.0 * 22 / 24) / 11.6638) * 10, 0.01));
    });

    test('derives rates for Lahore Rang Mahal Sarafa rate (Rs. 285,500 / Tola)', () {
      const double lahoreRate24k = 285500.0;
      final record = GoldRateRecord(
        id: 'rate_lahore_01',
        rate24kPerTola: lahoreRate24k,
        city: 'Lahore Sarafa Association',
      );

      expect(record.city, 'Lahore Sarafa Association');
      expect(record.rate24kPerTola, 285500.0);
      expect(record.rate22kPerTola, closeTo(285500.0 * 22 / 24, 0.01));
      expect(record.rate10g24k, closeTo((285500.0 / 11.6638) * 10, 0.01));
    });

    test('PreferencesService caches city rates and updates derived properties', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await PreferencesService.init();

      // Update to Karachi rate
      await prefs.updateSarafaRates(rate24kTola: 280000.0, city: 'Karachi Sarafa');
      expect(prefs.sarafaRate24kTola, 280000.0);
      expect(prefs.sarafaMarketCity, 'Karachi Sarafa');
      expect(prefs.sarafaRate22kTola, closeTo(280000.0 * 22 / 24, 0.01));
      expect(prefs.sarafaRate24k10g, closeTo((280000.0 / 11.6638038) * 10, 0.01));
      expect(prefs.sarafaRate22k10g, closeTo(((280000.0 * 22 / 24) / 11.6638038) * 10, 0.01));

      // Switch to Peshawar rate
      await prefs.updateSarafaRates(rate24kTola: 295000.0, city: 'Peshawar Khyber Bazaar');
      expect(prefs.sarafaRate24kTola, 295000.0);
      expect(prefs.sarafaMarketCity, 'Peshawar Khyber Bazaar');
      expect(prefs.sarafaRate22kTola, closeTo(295000.0 * 22 / 24, 0.01));
    });
  });

  group('3. Jewelry Bill Calculation Back-Testing (Purities, Mazdoori Modes, WhatsApp Parch)', () {
    test('Karachi Market 22K Jewelry Bill with stone deduction, flat Mazdoori, and discount', () {
      // Customer buys a 22K Gold Bangle in Karachi
      // Gross weight: 24.5g, Stone/Nageena: 1.5g -> Net gold: 23.0g
      // 24K Rate/Tola: Rs. 284,000
      // 22K Rate/Tola: 284,000 * (22/24) = 260,333.33 PKR
      // Rate per gram (22K): 260,333.33 / 11.6638 = 22,319.76 PKR/g
      // Gold Cost: 23.0 * 22,319.76 = 513,354.57 PKR
      // Making (Mazdoori): Rs. 6,500 flat
      // Discount (Riaayat): Rs. 1,500
      // Grand Total: 513,354.57 + 6,500 - 1,500 = 518,354.57 PKR
      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 24.5,
        stoneWeightGrams: 1.5,
        rate24kPerTola: 284000.0,
        karat: 22,
        makingCharges: 6500.0,
        discount: 1500.0,
      );

      expect(bill.netWeightGrams, 23.0);
      expect(bill.karat, 22);
      expect(bill.rate24kPerTola, 284000.0);
      expect(bill.karatRatePerTola, closeTo(284000.0 * 22 / 24, 0.01));
      expect(bill.goldCost, closeTo(513354.71, 0.1));
      expect(bill.makingCharges, 6500.0);
      expect(bill.discount, 1500.0);
      expect(bill.totalAmount, closeTo(518354.71, 0.1));

      // Traditional unit breakdown of 23.0 grams:
      // 23 / 11.6638 = 1.971913 Tola = 1 Tola, 11 Masha, ~5.33 Ratti
      final tmr = bill.traditionalUnits;
      expect(tmr.tola, 1);
      expect(tmr.masha, 11);
      expect(tmr.ratti, closeTo(5.33, 0.05));
    });

    test('Peshawar Market 21K Gulf Gold Necklace calculation at Rs. 292,000 / Tola', () {
      // Gross: 18.25g, Stone: 0.0g (plain gold chain)
      // 21K Purity: 21 / 24 = 0.875
      // 21K Rate/Tola: 292,000 * 0.875 = 255,500 PKR
      // Rate per gram: 255,500 / 11.6638 = 21,905.38 PKR/g
      // Gold Cost: 18.25 * 21,905.38 = 399,773.23 PKR
      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 18.25,
        stoneWeightGrams: 0.0,
        rate24kPerTola: 292000.0,
        karat: 21,
        makingCharges: 4000.0,
        discount: 0.0,
      );

      expect(bill.netWeightGrams, 18.25);
      expect(bill.karat, 21);
      expect(bill.karatRatePerTola, 255500.0);
      expect(bill.goldCost, closeTo(399773.23, 0.1));
      expect(bill.totalAmount, closeTo(403773.23, 0.1));
    });

    test('18K Diamond Setting Ring calculation at Rs. 280,000 / Tola', () {
      // Gross: 6.4g, Diamonds & Gemstones: 1.2g -> Net gold: 5.2g
      // 18K Purity = 18 / 24 = 0.75
      // 18K Rate/Tola = 280,000 * 0.75 = 210,000 PKR
      // Rate per gram = 210,000 / 11.6638 = 18,004.42 PKR/g
      // Gold Cost = 5.2 * 18,004.42 = 93,623.00 PKR
      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 6.4,
        stoneWeightGrams: 1.2,
        rate24kPerTola: 280000.0,
        karat: 18,
        makingCharges: 8000.0, // High setting labor
        discount: 500.0,
      );

      expect(bill.netWeightGrams, 5.2);
      expect(bill.karatRatePerTola, 210000.0);
      expect(bill.goldCost, closeTo(93623.00, 0.1));
      expect(bill.totalAmount, closeTo(101123.00, 0.1));
    });

    test('Mazdoori calculation modes (Flat, Per-Gram, and Percentage)', () {
      const double netGoldGrams = 15.0;
      const double rate24kTola = 285000.0;
      const int karat = 22;
      final double karatPurity = GoldMath.getPurityMultiplier(karat); // 0.916 in screen logic
      final double rate24kPerGram = rate24kTola / GoldMath.tolaInGrams;
      final double karatRatePerGram = rate24kPerGram * karatPurity;
      final double baseGoldValue = netGoldGrams * karatRatePerGram;

      // Mode 1: Flat PKR
      const double flatMazdooriInput = 4500.0;
      const double flatMaking = flatMazdooriInput;
      expect(flatMaking, 4500.0);

      // Mode 2: Per-Gram (e.g. Rs. 800 per gram)
      const double perGramInput = 800.0;
      final double perGramMaking = perGramInput * netGoldGrams;
      expect(perGramMaking, 12000.0);

      // Mode 3: Percentage (e.g. 8% of base gold value)
      const double percentInput = 8.0;
      final double percentMaking = baseGoldValue * (percentInput / 100.0);
      expect(percentMaking, closeTo(26858.48, 0.05));
      expect(percentMaking, closeTo(baseGoldValue * 0.08, 1e-6));
    });

    test('WhatsApp Parch receipt text formatting contains all required Sarafa fields', () {
      final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      const itemName = 'Peshawar Bridal Champa Haar';
      const selectedKarat = 22;
      const rate24kTola = 288000.0;
      const grossGrams = 32.500;
      const stoneGrams = 2.500;
      final netGoldGrams = grossGrams - stoneGrams; // 30.000g
      final tmr = GoldMath.gramsToTMR(netGoldGrams);
      const karatPurity = 0.916; // from GoldMath.getPurityMultiplier(22)
      final pureGoldGrams = netGoldGrams * karatPurity;
      final rate24kPerGram = rate24kTola / GoldMath.tolaInGrams;
      final karatRatePerGram = rate24kPerGram * karatPurity;
      final baseGoldValue = netGoldGrams * karatRatePerGram;
      const makingAmount = 7500.0;
      const discount = 2000.0;
      final totalPayable = baseGoldValue + makingAmount - discount;

      final formatter = NumberFormat('#,##,###');
      String formatPkr(double amount) => 'Rs. ${formatter.format(amount.round())}';

      final parchText = '''
🌟 *PAK GOLD PRO — SARAFA BILL / PARCH* 🌟
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 *Tareekh:* $now
💍 *Item:* $itemName
👑 *Gold Karat:* $selectedKarat K (${GoldMath.getHallmarkLabel(selectedKarat)})
💰 *24K Tola Rate:* ${formatPkr(rate24kTola)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ *Kul Wazan (Gross):* ${grossGrams.toStringAsFixed(3)} g
💎 *Nageena (Stone):* ${stoneGrams.toStringAsFixed(3)} g
✨ *Safi Sona (Net):* ${netGoldGrams.toStringAsFixed(3)} g
🏷️ *Tola/Masha/Ratti:* ${tmr.formatted}
🪙 *Khalis Sona (Pure):* ${pureGoldGrams.toStringAsFixed(3)} g
📈 *Pure Gold Rate/g:* ${formatPkr(karatRatePerGram)} / g
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💵 *Soney Ki Qeemat:* ${formatPkr(baseGoldValue)}
🔨 *Mazdoori (Making):* ${formatPkr(makingAmount)}
🏷️ *Discount (Riaayat):* ${formatPkr(discount)}
════════════════════════════
🏆 *KUL PAYABLE RAQAM:* ${formatPkr(totalPayable)}
════════════════════════════
✨ *Pak Gold Pro — Digital Sarafa Bahi-Khata*''';

      // Assertions on the generated Parch text
      expect(parchText, contains('*PAK GOLD PRO — SARAFA BILL / PARCH*'));
      expect(parchText, contains('*Item:* Peshawar Bridal Champa Haar'));
      expect(parchText, contains('*Gold Karat:* 22 K (916 Hallmark (Jewelry))'));
      expect(parchText, contains('32.500 g')); // Gross
      expect(parchText, contains('2.500 g'));  // Stone
      expect(parchText, contains('30.000 g')); // Net
      expect(parchText, contains('Tola'));
      expect(parchText, contains('Masha'));
      expect(parchText, contains('Ratti'));
      expect(parchText, contains('Mazdoori (Making):'));
      expect(parchText, contains('Discount (Riaayat):'));
      expect(parchText, contains('KUL PAYABLE RAQAM:'));
      expect(parchText, contains('Pak Gold Pro — Digital Sarafa Bahi-Khata'));
    });
  });

  group('4. Old Gold / Scrap Melter (Katoti & Katan) Back-Testing (1% to 5% Melting Loss)', () {
    test('GoldMathService.calculateScrapValue across 1% to 5% melting loss range', () {
      const double grossGrams = 20.0;
      const double stoneGrams = 2.0; // 18g net scrap
      const int karat = 22; // 22/24 purity
      const double rate24kTola = 285000.0;
      final double rate24kPerGram = rate24kTola / 11.6638;

      final lossPercentages = [1.0, 2.0, 2.5, 3.0, 4.0, 5.0];

      for (final lossPercent in lossPercentages) {
        final result = GoldMathService.calculateScrapValue(
          grossGrams: grossGrams,
          stoneGrams: stoneGrams,
          karat: karat,
          meltingLossPercent: lossPercent,
          rate24kPerTola: rate24kTola,
        );

        expect(result.netGrams, 18.0);
        final expectedMeltedGrams = 18.0 * (1.0 - (lossPercent / 100.0));
        expect(result.meltedGrams, closeTo(expectedMeltedGrams, 1e-6));

        final expectedPureGrams = expectedMeltedGrams * (22.0 / 24.0);
        expect(result.pureGrams, closeTo(expectedPureGrams, 1e-6));

        final expectedTotalValue = expectedPureGrams * rate24kPerGram;
        expect(result.totalValue, closeTo(expectedTotalValue, 1e-4));
      }
    });

    test('Old Gold Melter screen formula (Percentage Katan vs Gram Katan)', () {
      // 15g gross, 1.2g stone -> 13.8g net gold
      // Karat: 22K (multiplier 0.916 from GoldMath.getPurityMultiplier)
      const double grossWeight = 15.0;
      const double stoneWeight = 1.2;
      final double netGoldGrams = grossWeight - stoneWeight; // 13.8g
      final double purity = GoldMath.getPurityMultiplier(22); // 0.916
      final double pureGoldWeight = netGoldGrams * purity; // 13.8 * 0.916 = 12.6408g

      const double rate24kTola = 285000.0;
      final double rate24kPerGram = rate24kTola / GoldMath.tolaInGrams;

      // Case A: 2% Katan
      const double katanPercent = 2.0;
      final double lossGramsPercent = pureGoldWeight * (katanPercent / 100.0); // 0.252816g
      final double payableWeightPercent = pureGoldWeight - lossGramsPercent; // 12.387984g
      final double payoutPercent = payableWeightPercent * rate24kPerGram;
      expect(lossGramsPercent, closeTo(0.2528, 0.001));
      expect(payoutPercent, closeTo(12.387984 * (285000.0 / 11.6638038), 0.1));

      // Case B: 0.5g fixed Gram Katan
      const double katanGramsInput = 0.5;
      final double lossGramsFixed = katanGramsInput.clamp(0.0, pureGoldWeight);
      final double payableWeightFixed = pureGoldWeight - lossGramsFixed; // 12.1408g
      final double payoutFixed = payableWeightFixed * rate24kPerGram;
      expect(payableWeightFixed, closeTo(12.1408, 0.001));
      expect(payoutFixed, closeTo(12.1408 * (285000.0 / 11.6638038), 0.1));
    });

    test('Old Gold WhatsApp Scrap Parch receipt generation', () {
      final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      const title = 'Haji Abdullah - Peshawar Scrap Exchange';
      const selectedKarat = 22;
      const rate24kTola = 286000.0;
      final rate24kPerGram = rate24kTola / GoldMath.tolaInGrams;
      const grossWeight = 25.0;
      const stoneWeight = 1.5;
      final netGoldGrams = grossWeight - stoneWeight; // 23.5g
      final tmr = GoldMath.gramsToTMR(netGoldGrams);
      final purity = GoldMath.getPurityMultiplier(selectedKarat);
      final pureGoldWeight = netGoldGrams * purity;
      const katanLoss = 3.0; // 3%
      final lossGrams = pureGoldWeight * (katanLoss / 100.0);
      final payableGoldWeight = pureGoldWeight - lossGrams;
      final scrapPayout = payableGoldWeight * rate24kPerGram;

      final formatter = NumberFormat('#,##,###');
      String formatPkr(double amount) => 'Rs. ${formatter.format(amount.round())}';

      final scrapParchText = '''
🌟 *PAK GOLD PRO — OLD GOLD / SCRAP PARCH* 🌟
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 *Tareekh:* $now
👤 *Reference:* $title
👑 *Gold Karat:* $selectedKarat K (${GoldMath.getHallmarkLabel(selectedKarat)})
💰 *24K Tola Rate:* ${formatPkr(rate24kTola)}
📈 *Pure Gold Rate/g:* ${formatPkr(rate24kPerGram)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ *Kul Wazan (Gross):* ${grossWeight.toStringAsFixed(3)} g
💎 *Nageena (Stone):* ${stoneWeight.toStringAsFixed(3)} g
✨ *Safi Wazan (Net):* ${netGoldGrams.toStringAsFixed(3)} g
🏷️ *Tola/Masha/Ratti:* ${tmr.formatted}
🪙 *Khalis Sona (Pure 24K):* ${pureGoldWeight.toStringAsFixed(3)} g
🔥 *Katan / Katoti (3.0%):* ${lossGrams.toStringAsFixed(3)} g
⚖️ *Payable Gold Weight:* ${payableGoldWeight.toStringAsFixed(3)} g
════════════════════════════
💵 *KUL CASH PAYOUT (Raqam):* ${formatPkr(scrapPayout)}
════════════════════════════
✨ *Pak Gold Pro — Digital Sarafa Bahi-Khata*''';

      expect(scrapParchText, contains('*PAK GOLD PRO — OLD GOLD / SCRAP PARCH*'));
      expect(scrapParchText, contains('Haji Abdullah - Peshawar Scrap Exchange'));
      expect(scrapParchText, contains('Katan / Katoti (3.0%)'));
      expect(scrapParchText, contains('KUL CASH PAYOUT (Raqam):'));
    });
  });

  group('5. Storage Persistence (Multiple Peshawar & Karachi Bills & Historical Rates)', () {
    test('saves, retrieves, updates, and deletes multiple Karachi and Peshawar bills', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SarafaStorage.init();

      // Bill 1: Karachi Sarafa Bangle
      final billKarachi = JewelryBill.fromCalculation(
        id: 'bill_karachi_101',
        customerName: 'Muhammad Salman',
        customerPhone: '03001234567',
        itemName: 'Karachi 22K Bridal Bangle',
        grossWeightGrams: 28.5,
        stoneWeightGrams: 2.0,
        rate24kPerTola: 284000.0,
        karat: 22,
        makingCharges: 5000.0,
        discount: 1000.0,
        notes: 'Karachi Sarafa Market Deal',
      );

      // Bill 2: Peshawar Sarafa Haar
      final billPeshawar = JewelryBill.fromCalculation(
        id: 'bill_peshawar_202',
        customerName: 'Gul Khan Afridi',
        customerPhone: '03339876543',
        itemName: 'Peshawar Khyber Guluband',
        grossWeightGrams: 45.0,
        stoneWeightGrams: 3.5,
        rate24kPerTola: 286500.0,
        karat: 22,
        makingCharges: 8000.0,
        discount: 2500.0,
        notes: 'Peshawar Andar Shehar Sarafa',
      );

      // Bill 3: Lahore Kundan Ring
      final billLahore = JewelryBill.fromCalculation(
        id: 'bill_lahore_303',
        customerName: 'Taimoor Shah',
        customerPhone: '03215554433',
        itemName: 'Lahore Rang Mahal 24K Kundan Ring',
        grossWeightGrams: 11.6638, // 1 tola
        stoneWeightGrams: 0.0,
        rate24kPerTola: 285000.0,
        karat: 24,
        makingCharges: 3000.0,
        discount: 0.0,
        notes: 'Suha Bazaar Kundan',
      );

      // Save all 3 bills
      await storage.saveBill(billKarachi);
      await storage.saveBill(billPeshawar);
      await storage.saveBill(billLahore);

      final bills = storage.getBills();
      expect(bills.length, 3);
      // Newest bill saved is placed first
      expect(bills[0].id, 'bill_lahore_303');
      expect(bills[1].id, 'bill_peshawar_202');
      expect(bills[2].id, 'bill_karachi_101');

      // Verify bill fidelity
      final retrievedPeshawar = bills.firstWhere((b) => b.id == 'bill_peshawar_202');
      expect(retrievedPeshawar.customerName, 'Gul Khan Afridi');
      expect(retrievedPeshawar.itemName, 'Peshawar Khyber Guluband');
      expect(retrievedPeshawar.grossWeightGrams, 45.0);
      expect(retrievedPeshawar.stoneWeightGrams, 3.5);
      expect(retrievedPeshawar.netWeightGrams, 41.5);
      expect(retrievedPeshawar.notes, 'Peshawar Andar Shehar Sarafa');

      // Update billKarachi with modified discount
      final updatedKarachi = JewelryBill.fromCalculation(
        id: 'bill_karachi_101',
        customerName: 'Muhammad Salman',
        customerPhone: '03001234567',
        itemName: 'Karachi 22K Bridal Bangle (Updated)',
        grossWeightGrams: 28.5,
        stoneWeightGrams: 2.0,
        rate24kPerTola: 284000.0,
        karat: 22,
        makingCharges: 5000.0,
        discount: 2000.0, // increased discount
        notes: 'Karachi Sarafa Market Deal - Special Rate',
      );
      await storage.saveBill(updatedKarachi);

      final updatedBills = storage.getBills();
      expect(updatedBills.length, 3); // No duplicates
      final verifiedUpdated = updatedBills.firstWhere((b) => b.id == 'bill_karachi_101');
      expect(verifiedUpdated.itemName, 'Karachi 22K Bridal Bangle (Updated)');
      expect(verifiedUpdated.discount, 2000.0);

      // Delete Lahore bill
      final deleteSuccess = await storage.deleteBill('bill_lahore_303');
      expect(deleteSuccess, isTrue);
      expect(storage.getBills().length, 2);

      // Clear all
      await storage.clearBills();
      expect(storage.getBills().isEmpty, isTrue);
    });

    test('saves and retrieves historical market rates across major Sarafa hubs', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SarafaStorage.init();

      final rateKarachi = GoldRateRecord(
        id: 'rate_khi_20261108',
        rate24kPerTola: 283500.0,
        city: 'Karachi Sarafa',
      );
      final ratePeshawar = GoldRateRecord(
        id: 'rate_pew_20261108',
        rate24kPerTola: 284200.0,
        city: 'Peshawar Sarafa',
      );
      final rateLahore = GoldRateRecord(
        id: 'rate_lhe_20261108',
        rate24kPerTola: 283800.0,
        city: 'Lahore Sarafa',
      );

      await storage.saveRate(rateKarachi);
      await storage.saveRate(ratePeshawar);
      await storage.saveRate(rateLahore);

      final historicalRates = storage.getHistoricalRates();
      expect(historicalRates.length, 3);
      expect(historicalRates.first.city, 'Lahore Sarafa'); // Newest first

      final latestRate = storage.getLatestRate();
      expect(latestRate?.rate24kPerTola, 283800.0);
      expect(storage.getCached24kRate(), 283800.0);
    });
  });

  group('6. Edge Case Resilience (Zero, Negative, Micro-weights, Extreme Quantities)', () {
    test('zero and negative gross weight clamped safely to 0', () {
      final zeroBill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 0.0,
        rate24kPerTola: 285000.0,
      );
      expect(zeroBill.netWeightGrams, 0.0);
      expect(zeroBill.netTola, 0.0);
      expect(zeroBill.goldCost, 0.0);
      expect(zeroBill.totalAmount, 0.0);

      final negBill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: -10.0,
        rate24kPerTola: 285000.0,
      );
      expect(negBill.netWeightGrams, 0.0);
      expect(negBill.totalAmount, 0.0);
    });

    test('stone weight exceeding gross weight clamps net gold weight to 0', () {
      // 5g gross, 8g stone
      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 5.0,
        stoneWeightGrams: 8.0,
        rate24kPerTola: 285000.0,
        makingCharges: 1000.0,
      );
      expect(bill.netWeightGrams, 0.0);
      expect(bill.goldCost, 0.0);
      expect(bill.totalAmount, 1000.0); // Only making charges remain
    });

    test('discount exceeding gold cost + making charges clamps total to 0 (no negative debt)', () {
      final bill = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 1.0,
        rate24kPerTola: 280000.0,
        makingCharges: 500.0,
        discount: 50000.0, // Exceeds entire bill
      );
      expect(bill.totalAmount, 0.0);
    });

    test('very small micro-weights (e.g. 0.001g, 0.0001g, 0.05 Ratti)', () {
      // 0.001g
      final tmrMicro = GoldMathService.gramsToTraditionalUnits(0.001);
      expect(tmrMicro.tola, 0);
      expect(tmrMicro.masha, 0);
      expect(tmrMicro.ratti, closeTo(0.0082, 0.001));

      final billMicro = GoldMathService.calculateJewelryBill(
        grossWeightGrams: 0.001,
        rate24kPerTola: 285000.0,
        karat: 24,
      );
      expect(billMicro.goldCost, closeTo(24.43, 0.05)); // ~Rs. 24.43
    });

    test('large quantities back-testing (100 Tolas commercial bullion bar)', () {
      // 100 Tolas = 1166.38 grams
      const double tolaCount = 100.0;
      final double grossGrams = tolaCount * GoldMathService.gramPerTola;
      const double rate24kTola = 285000.0;

      final billBullion = GoldMathService.calculateJewelryBill(
        grossWeightGrams: grossGrams,
        rate24kPerTola: rate24kTola,
        karat: 24,
      );

      expect(billBullion.netWeightGrams, 1166.38);
      expect(billBullion.netTola, closeTo(100.0, 1e-6));
      // 100 tolas * 285,000 = 28,500,000 PKR (2 Crore 85 Lakh PKR)
      expect(billBullion.totalAmount, closeTo(28500000.0, 0.01));

      // Traditional unit conversion of 100 tolas
      final tmrBullion = GoldMathService.gramsToTraditionalUnits(grossGrams);
      expect(tmrBullion.tola, 100);
      expect(tmrBullion.masha, 0);
      expect(tmrBullion.ratti, 0.0);
    });

    test('scrap melting loss edge cases: 0% loss, 100% loss, and >100% loss', () {
      // 0% loss
      final scrapZeroLoss = GoldMathService.calculateScrapValue(
        grossGrams: 10.0,
        meltingLossPercent: 0.0,
        rate24kPerTola: 280000.0,
      );
      expect(scrapZeroLoss.meltedGrams, 10.0);

      // 100% loss (dross/complete incineration)
      final scrap100Loss = GoldMathService.calculateScrapValue(
        grossGrams: 10.0,
        meltingLossPercent: 100.0,
        rate24kPerTola: 280000.0,
      );
      expect(scrap100Loss.meltedGrams, 0.0);
      expect(scrap100Loss.pureGrams, 0.0);
      expect(scrap100Loss.totalValue, 0.0);

      // >100% loss clamped safely
      final scrapOverLoss = GoldMathService.calculateScrapValue(
        grossGrams: 10.0,
        meltingLossPercent: 150.0,
        rate24kPerTola: 280000.0,
      );
      expect(scrapOverLoss.meltedGrams, 0.0);
      expect(scrapOverLoss.totalValue, 0.0);
    });
  });
}
