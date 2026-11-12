class TmrBreakdown {
  final int tola;
  final int masha;
  final double ratti;
  final double totalTola;
  final double totalGrams;

  const TmrBreakdown({
    required this.tola,
    required this.masha,
    required this.ratti,
    required this.totalTola,
    required this.totalGrams,
  });

  String get formatted {
    final rattiStr = ratti.toStringAsFixed(2);
    return '$tola Tola, $masha Masha, $rattiStr Ratti';
  }
}

class GoldMath {
  // Conversion factors based on Pakistan Sarafa standard
  static const double tolaInGrams = 11.6638038;
  static const double mashaInGrams = tolaInGrams / 12.0; // 0.97198365 g
  static const double rattiInGrams = tolaInGrams / 96.0; // 0.12149795 g
  static const double troyOunceInGrams = 31.1034768;
  static const double sovereignInGrams = 8.0;
  static const double kgInGrams = 1000.0;

  static double convertToGrams(double weight, String unit) {
    switch (unit.toLowerCase()) {
      case 'tola':
        return weight * tolaInGrams;
      case 'masha':
        return weight * mashaInGrams;
      case 'ratti':
        return weight * rattiInGrams;
      case 'oz':
      case 'troy ounce':
        return weight * troyOunceInGrams;
      case 'pavan':
      case 'sovereign':
        return weight * sovereignInGrams;
      case 'kg':
        return weight * kgInGrams;
      case 'g':
      case 'gram':
      default:
        return weight;
    }
  }

  static double convertFromGrams(double grams, String targetUnit) {
    switch (targetUnit.toLowerCase()) {
      case 'tola':
        return grams / tolaInGrams;
      case 'masha':
        return grams / mashaInGrams;
      case 'ratti':
        return grams / rattiInGrams;
      case 'oz':
      case 'troy ounce':
        return grams / troyOunceInGrams;
      case 'pavan':
      case 'sovereign':
        return grams / sovereignInGrams;
      case 'kg':
        return grams / kgInGrams;
      case 'g':
      case 'gram':
      default:
        return grams;
    }
  }

  /// Converts grams to traditional Tola-Masha-Ratti breakdown
  static TmrBreakdown gramsToTMR(double grams) {
    if (grams <= 0) {
      return const TmrBreakdown(
        tola: 0,
        masha: 0,
        ratti: 0.0,
        totalTola: 0.0,
        totalGrams: 0.0,
      );
    }

    final totalTola = grams / tolaInGrams;
    final int tola = totalTola.floor();
    final double remainderAfterTolaGrams = grams - (tola * tolaInGrams);

    final double totalMasha = remainderAfterTolaGrams / mashaInGrams;
    final int masha = totalMasha.floor();
    final double remainderAfterMashaGrams = remainderAfterTolaGrams - (masha * mashaInGrams);

    final double ratti = remainderAfterMashaGrams / rattiInGrams;

    return TmrBreakdown(
      tola: tola,
      masha: masha,
      ratti: ratti,
      totalTola: totalTola,
      totalGrams: grams,
    );
  }

  /// Converts Tola, Masha, Ratti inputs into total grams
  static double tmrToGrams({double tola = 0.0, double masha = 0.0, double ratti = 0.0}) {
    return (tola * tolaInGrams) + (masha * mashaInGrams) + (ratti * rattiInGrams);
  }

  static double getPurityMultiplier(int karat) {
    switch (karat) {
      case 24:
        return 0.999;
      case 22:
        return 0.916; // 91.6% Hallmark / Traditional Pakistani jewelry
      case 21:
        return 0.875; // 87.5% Gulf / Arab standard
      case 18:
        return 0.750; // 75.0% Diamond / stone setting
      case 16:
        return 0.667; // 66.7% Commercial gold
      case 14:
        return 0.585; // 58.5% European hallmark
      case 12:
        return 0.500; // 50.0% Half gold
      case 10:
        return 0.417; // 41.7% American hallmark
      case 9:
        return 0.375; // 37.5% Antique hallmark
      case 8:
        return 0.333; // 33.3% Low purity gold
      default:
        return (karat / 24.0).clamp(0.0, 1.0);
    }
  }

  static String getHallmarkLabel(int karat) {
    switch (karat) {
      case 24:
        return '999 Pure (Kundan)';
      case 22:
        return '916 Hallmark (Jewelry)';
      case 21:
        return '875 Hallmark (Gulf)';
      case 18:
        return '750 Hallmark (Diamond)';
      case 16:
        return '667 Hallmark';
      case 14:
        return '585 Hallmark';
      case 12:
        return '500 Hallmark (Half Gold)';
      case 10:
        return '417 Hallmark';
      case 9:
        return '375 Hallmark';
      case 8:
        return '333 Hallmark';
      default:
        return '${(getPurityMultiplier(karat) * 100).toStringAsFixed(1)}%';
    }
  }
}
