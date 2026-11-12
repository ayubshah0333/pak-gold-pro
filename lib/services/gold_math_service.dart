/// Pakistani Sarafa (Jewelry Market) Gold Calculation Engine
///
/// Implements standard Pakistani gold units:
/// - 1 Tola = 11.6638 grams
/// - 1 Tola = 12 Masha (1 Masha = 11.6638 / 12 = ~0.97198 g)
/// - 1 Tola = 96 Ratti (1 Masha = 8 Ratti; 1 Ratti = 11.6638 / 96 = ~0.1215 g)
class GoldMathService {
  /// 1 Tola in metric grams (Pakistani Sarafa standard)
  static const double gramPerTola = 11.6638;

  /// Number of Masha in 1 Tola
  static const double mashaPerTola = 12.0;

  /// Number of Ratti in 1 Tola (12 Masha * 8 Ratti)
  static const double rattiPerTola = 96.0;

  /// Number of Ratti in 1 Masha
  static const double rattiPerMasha = 8.0;

  /// Grams per Masha (11.6638 / 12)
  static const double gramPerMasha = gramPerTola / mashaPerTola;

  /// Grams per Ratti (11.6638 / 96)
  static const double gramPerRatti = gramPerTola / rattiPerTola;

  /// Converts Pakistani traditional gold units (Tola, Masha, Ratti) + grams to total metric Grams.
  ///
  /// Formula: grams + (tola * 11.6638) + (masha * (11.6638 / 12)) + (ratti * (11.6638 / 96))
  static double toGrams({
    double tola = 0.0,
    double masha = 0.0,
    double ratti = 0.0,
    double grams = 0.0,
  }) {
    return grams +
        (tola * gramPerTola) +
        (masha * gramPerMasha) +
        (ratti * gramPerRatti);
  }

  /// Converts a metric weight in Grams into traditional Pakistani Sarafa units:
  /// - tola (integer part)
  /// - masha (integer part, 0..11)
  /// - ratti (decimal part, 0.0 .. <8.0)
  /// - totalTola (full decimal tola weight)
  static TraditionalGoldUnits gramsToTraditionalUnits(double totalGrams) {
    if (totalGrams <= 0.0) {
      return const TraditionalGoldUnits(
        tola: 0,
        masha: 0,
        ratti: 0.0,
        totalTola: 0.0,
      );
    }

    final double totalTola = totalGrams / gramPerTola;
    int tola = totalTola.floor();
    final double remainingTola = totalTola - tola;

    final double totalMasha = remainingTola * mashaPerTola;
    int masha = totalMasha.floor();
    final double remainingMasha = totalMasha - masha;

    double ratti = remainingMasha * rattiPerMasha;

    // Handle floating-point precision edge case (e.g. 7.999999999 -> 8)
    if ((ratti - rattiPerMasha).abs() < 1e-5 || ratti >= rattiPerMasha - 1e-5) {
      ratti = 0.0;
      masha += 1;
    }
    if (masha >= mashaPerTola.toInt()) {
      masha -= mashaPerTola.toInt();
      tola += 1;
    }

    // Round ratti to 4 decimal places for precision display
    ratti = (ratti * 10000.0).roundToDouble() / 10000.0;

    return TraditionalGoldUnits(
      tola: tola,
      masha: masha,
      ratti: ratti,
      totalTola: totalTola,
    );
  }

  /// Calculates a complete Pakistani Sarafa Jewelry Bill.
  ///
  /// - [grossWeightGrams]: Total weight of the jewelry piece (gold + stones/nageena)
  /// - [stoneWeightGrams]: Weight of stones/nageena to deduct (Kaat / Nageena)
  /// - [rate24kPerTola]: Current 24K gold rate per tola in PKR
  /// - [karat]: Gold karat purity (standard: 24, 22, 21, 18)
  /// - [makingCharges]: Jewelry making charges (Mazdoori) in PKR
  /// - [discount]: Discount given to customer in PKR
  static JewelryBillResult calculateJewelryBill({
    required double grossWeightGrams,
    double stoneWeightGrams = 0.0,
    required double rate24kPerTola,
    int karat = 24,
    double makingCharges = 0.0,
    double discount = 0.0,
  }) {
    final double netWeightGrams =
        (grossWeightGrams - stoneWeightGrams).clamp(0.0, double.infinity);
    final double netTola = netWeightGrams / gramPerTola;

    final double purityMultiplier = (karat / 24.0).clamp(0.0, 1.0);
    final double karatRatePerTola = rate24kPerTola * purityMultiplier;
    final double karatRatePerGram = karatRatePerTola / gramPerTola;

    final double goldCost = netWeightGrams * karatRatePerGram;
    final double totalAmount =
        (goldCost + makingCharges - discount).clamp(0.0, double.infinity);

    return JewelryBillResult(
      grossWeightGrams: grossWeightGrams,
      stoneWeightGrams: stoneWeightGrams,
      netWeightGrams: netWeightGrams,
      netTola: netTola,
      karat: karat,
      rate24kPerTola: rate24kPerTola,
      karatRatePerTola: karatRatePerTola,
      karatRatePerGram: karatRatePerGram,
      goldCost: goldCost,
      makingCharges: makingCharges,
      discount: discount,
      totalAmount: totalAmount,
    );
  }

  /// Calculates the scrap / old gold value (Purana Sona / Khad / Katcha Sona).
  ///
  /// - [grossGrams]: Total gross weight of the scrap piece
  /// - [stoneGrams]: Stone/impurity weight to deduct
  /// - [karat]: Gold purity of scrap
  /// - [meltingLossPercent]: Kass/katcha melting loss percentage (e.g. 2.0 = 2%)
  /// - [rate24kPerTola]: 24K gold rate per tola
  static ScrapGoldResult calculateScrapValue({
    required double grossGrams,
    double stoneGrams = 0.0,
    int karat = 24,
    double meltingLossPercent = 0.0,
    required double rate24kPerTola,
  }) {
    final double netGrams =
        (grossGrams - stoneGrams).clamp(0.0, double.infinity);

    final double meltingLossFactor =
        (1.0 - (meltingLossPercent / 100.0)).clamp(0.0, 1.0);
    final double meltedGrams = netGrams * meltingLossFactor;

    final double purityMultiplier = (karat / 24.0).clamp(0.0, 1.0);
    final double pureGrams = meltedGrams * purityMultiplier;
    final double pureTola = pureGrams / gramPerTola;

    final double rate24kPerGram = rate24kPerTola / gramPerTola;
    final double totalValue = pureGrams * rate24kPerGram;

    return ScrapGoldResult(
      grossGrams: grossGrams,
      stoneGrams: stoneGrams,
      netGrams: netGrams,
      meltingLossPercent: meltingLossPercent,
      meltedGrams: meltedGrams,
      karat: karat,
      pureGrams: pureGrams,
      pureTola: pureTola,
      rate24kPerTola: rate24kPerTola,
      rate24kPerGram: rate24kPerGram,
      totalValue: totalValue,
    );
  }

  /// Calculates the official Sarafa rate for 10 Grams of gold for any Karat.
  ///
  /// In Pakistani Sarafa, 10 Grams is the primary metric market quotation alongside per Tola.
  static double calculate10GramRate(double rate24kPerTola, int karat) {
    final double ratePerGram24k = rate24kPerTola / gramPerTola;
    final double purity = (karat / 24.0).clamp(0.0, 1.0);
    final double karatRatePerGram = ratePerGram24k * purity;
    return karatRatePerGram * 10.0;
  }
}

/// Represents gold weight split into traditional Pakistani Sarafa units.
class TraditionalGoldUnits {
  final int tola;
  final int masha;
  final double ratti;
  final double totalTola;

  const TraditionalGoldUnits({
    required this.tola,
    required this.masha,
    required this.ratti,
    required this.totalTola,
  });

  /// Formatted string in traditional Sarafa notation (e.g. "2 Tola 5 Masha 3.20 Ratti")
  String get formatted {
    final rattiStr = ratti % 1 == 0 ? ratti.toInt().toString() : ratti.toStringAsFixed(2);
    return '$tola Tola $masha Masha $rattiStr Ratti';
  }

  /// Formatted string with Urdu unit terms (تولہ، ماشہ، رتی)
  String get formattedUrdu {
    final rattiStr = ratti % 1 == 0 ? ratti.toInt().toString() : ratti.toStringAsFixed(2);
    return '$tola تولہ $masha ماشہ $rattiStr رتی';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TraditionalGoldUnits &&
          runtimeType == other.runtimeType &&
          tola == other.tola &&
          masha == other.masha &&
          (ratti - other.ratti).abs() < 1e-4 &&
          (totalTola - other.totalTola).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(tola, masha, ratti, totalTola);

  @override
  String toString() =>
      'TraditionalGoldUnits(tola: $tola, masha: $masha, ratti: $ratti, totalTola: ${totalTola.toStringAsFixed(4)})';
}

/// Detailed calculation result for a jewelry invoice.
class JewelryBillResult {
  final double grossWeightGrams;
  final double stoneWeightGrams;
  final double netWeightGrams;
  final double netTola;
  final int karat;
  final double rate24kPerTola;
  final double karatRatePerTola;
  final double karatRatePerGram;
  final double goldCost;
  final double makingCharges;
  final double discount;
  final double totalAmount;

  const JewelryBillResult({
    required this.grossWeightGrams,
    required this.stoneWeightGrams,
    required this.netWeightGrams,
    required this.netTola,
    required this.karat,
    required this.rate24kPerTola,
    required this.karatRatePerTola,
    required this.karatRatePerGram,
    required this.goldCost,
    required this.makingCharges,
    required this.discount,
    required this.totalAmount,
  });

  TraditionalGoldUnits get traditionalUnits =>
      GoldMathService.gramsToTraditionalUnits(netWeightGrams);

  @override
  String toString() =>
      'JewelryBillResult(netWeight: ${netWeightGrams.toStringAsFixed(3)}g, netTola: ${netTola.toStringAsFixed(4)}, total: PKR ${totalAmount.toStringAsFixed(2)})';
}

/// Detailed calculation result for scrap/old gold valuation.
class ScrapGoldResult {
  final double grossGrams;
  final double stoneGrams;
  final double netGrams;
  final double meltingLossPercent;
  final double meltedGrams;
  final int karat;
  final double pureGrams;
  final double pureTola;
  final double rate24kPerTola;
  final double rate24kPerGram;
  final double totalValue;

  const ScrapGoldResult({
    required this.grossGrams,
    required this.stoneGrams,
    required this.netGrams,
    required this.meltingLossPercent,
    required this.meltedGrams,
    required this.karat,
    required this.pureGrams,
    required this.pureTola,
    required this.rate24kPerTola,
    required this.rate24kPerGram,
    required this.totalValue,
  });

  TraditionalGoldUnits get pureTraditionalUnits =>
      GoldMathService.gramsToTraditionalUnits(pureGrams);

  @override
  String toString() =>
      'ScrapGoldResult(net: ${netGrams.toStringAsFixed(3)}g, pure: ${pureGrams.toStringAsFixed(3)}g, value: PKR ${totalValue.toStringAsFixed(2)})';
}
