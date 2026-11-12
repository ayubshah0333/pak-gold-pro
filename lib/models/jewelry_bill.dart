import 'dart:convert';
import '../services/gold_math_service.dart';

/// Represents an itemized jewelry sales invoice or quotation according to Pakistani Sarafa standards.
class JewelryBill {
  final String id;
  final String customerName;
  final String customerPhone;
  final String itemName;
  final DateTime dateTime;
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
  final String? notes;

  JewelryBill({
    required this.id,
    this.customerName = '',
    this.customerPhone = '',
    this.itemName = 'Gold Jewelry',
    DateTime? dateTime,
    required this.grossWeightGrams,
    this.stoneWeightGrams = 0.0,
    required this.netWeightGrams,
    required this.netTola,
    required this.karat,
    required this.rate24kPerTola,
    required this.karatRatePerTola,
    required this.karatRatePerGram,
    required this.goldCost,
    this.makingCharges = 0.0,
    this.discount = 0.0,
    required this.totalAmount,
    this.notes,
  }) : dateTime = dateTime ?? DateTime.now();

  /// Creates a [JewelryBill] computed directly via [GoldMathService].
  factory JewelryBill.fromCalculation({
    required String id,
    String customerName = '',
    String customerPhone = '',
    String itemName = 'Gold Jewelry',
    DateTime? dateTime,
    required double grossWeightGrams,
    double stoneWeightGrams = 0.0,
    required double rate24kPerTola,
    int karat = 22,
    double makingCharges = 0.0,
    double discount = 0.0,
    String? notes,
  }) {
    final calc = GoldMathService.calculateJewelryBill(
      grossWeightGrams: grossWeightGrams,
      stoneWeightGrams: stoneWeightGrams,
      rate24kPerTola: rate24kPerTola,
      karat: karat,
      makingCharges: makingCharges,
      discount: discount,
    );

    return JewelryBill(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      itemName: itemName,
      dateTime: dateTime ?? DateTime.now(),
      grossWeightGrams: calc.grossWeightGrams,
      stoneWeightGrams: calc.stoneWeightGrams,
      netWeightGrams: calc.netWeightGrams,
      netTola: calc.netTola,
      karat: calc.karat,
      rate24kPerTola: calc.rate24kPerTola,
      karatRatePerTola: calc.karatRatePerTola,
      karatRatePerGram: calc.karatRatePerGram,
      goldCost: calc.goldCost,
      makingCharges: calc.makingCharges,
      discount: calc.discount,
      totalAmount: calc.totalAmount,
      notes: notes,
    );
  }

  /// Returns weight converted into Pakistani Tola, Masha, Ratti.
  TraditionalGoldUnits get traditionalUnits =>
      GoldMathService.gramsToTraditionalUnits(netWeightGrams);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'itemName': itemName,
      'dateTime': dateTime.toIso8601String(),
      'grossWeightGrams': grossWeightGrams,
      'stoneWeightGrams': stoneWeightGrams,
      'netWeightGrams': netWeightGrams,
      'netTola': netTola,
      'karat': karat,
      'rate24kPerTola': rate24kPerTola,
      'karatRatePerTola': karatRatePerTola,
      'karatRatePerGram': karatRatePerGram,
      'goldCost': goldCost,
      'makingCharges': makingCharges,
      'discount': discount,
      'totalAmount': totalAmount,
      if (notes != null) 'notes': notes,
    };
  }

  factory JewelryBill.fromMap(Map<String, dynamic> map) {
    return JewelryBill(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      itemName: map['itemName'] ?? 'Gold Jewelry',
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
      grossWeightGrams: (map['grossWeightGrams'] as num?)?.toDouble() ?? 0.0,
      stoneWeightGrams: (map['stoneWeightGrams'] as num?)?.toDouble() ?? 0.0,
      netWeightGrams: (map['netWeightGrams'] as num?)?.toDouble() ?? 0.0,
      netTola: (map['netTola'] as num?)?.toDouble() ?? 0.0,
      karat: (map['karat'] as num?)?.toInt() ?? 24,
      rate24kPerTola: (map['rate24kPerTola'] as num?)?.toDouble() ?? 0.0,
      karatRatePerTola: (map['karatRatePerTola'] as num?)?.toDouble() ?? 0.0,
      karatRatePerGram: (map['karatRatePerGram'] as num?)?.toDouble() ?? 0.0,
      goldCost: (map['goldCost'] as num?)?.toDouble() ?? 0.0,
      makingCharges: (map['makingCharges'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory JewelryBill.fromJson(String source) =>
      JewelryBill.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Historical gold rate snapshot for Sarafa market tracking.
class GoldRateRecord {
  final String id;
  final DateTime dateTime;
  final double rate24kPerTola;
  final double rate22kPerTola;
  final double rate21kPerTola;
  final double rate18kPerTola;
  final double rate10g24k;
  final double rate10g22k;
  final String city;
  final String? notes;

  GoldRateRecord({
    required this.id,
    DateTime? dateTime,
    required this.rate24kPerTola,
    double? rate22kPerTola,
    double? rate21kPerTola,
    double? rate18kPerTola,
    double? rate10g24k,
    double? rate10g22k,
    this.city = 'Pakistan Sarafa',
    this.notes,
  })  : dateTime = dateTime ?? DateTime.now(),
        rate22kPerTola = rate22kPerTola ?? (rate24kPerTola * 22.0 / 24.0),
        rate21kPerTola = rate21kPerTola ?? (rate24kPerTola * 21.0 / 24.0),
        rate18kPerTola = rate18kPerTola ?? (rate24kPerTola * 18.0 / 24.0),
        rate10g24k = rate10g24k ??
            GoldMathService.calculate10GramRate(rate24kPerTola, 24),
        rate10g22k = rate10g22k ??
            GoldMathService.calculate10GramRate(rate24kPerTola, 22);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'rate24kPerTola': rate24kPerTola,
      'rate22kPerTola': rate22kPerTola,
      'rate21kPerTola': rate21kPerTola,
      'rate18kPerTola': rate18kPerTola,
      'rate10g24k': rate10g24k,
      'rate10g22k': rate10g22k,
      'city': city,
      if (notes != null) 'notes': notes,
    };
  }

  factory GoldRateRecord.fromMap(Map<String, dynamic> map) {
    return GoldRateRecord(
      id: map['id'] ?? '',
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
      rate24kPerTola: (map['rate24kPerTola'] as num?)?.toDouble() ?? 0.0,
      rate22kPerTola: (map['rate22kPerTola'] as num?)?.toDouble() ?? 0.0,
      rate21kPerTola: (map['rate21kPerTola'] as num?)?.toDouble() ?? 0.0,
      rate18kPerTola: (map['rate18kPerTola'] as num?)?.toDouble() ?? 0.0,
      rate10g24k: (map['rate10g24k'] as num?)?.toDouble() ?? 0.0,
      rate10g22k: (map['rate10g22k'] as num?)?.toDouble() ?? 0.0,
      city: map['city'] ?? 'Pakistan Sarafa',
      notes: map['notes'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GoldRateRecord.fromJson(String source) =>
      GoldRateRecord.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
