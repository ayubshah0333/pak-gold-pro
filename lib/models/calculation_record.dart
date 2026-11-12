import 'dart:convert';

class CalculationRecord {
  final String id;
  final String title;
  final DateTime timestamp;
  final String type; // 'jewelry', 'scrap', 'investment'
  final double weight; // Net weight in grams
  final String unit; // 'g', 'tola', 'oz', 'pavan'
  final int karat;
  final double ratePerGram;
  final double totalAmount;
  final double pureGoldWeight;
  final double makingCharges;
  final double taxAmount;
  final String currency;
  final double grossWeight;
  final double stoneWeight;
  final double discount;
  final double lossPercent;
  final String notes;

  CalculationRecord({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.type,
    required this.weight,
    required this.unit,
    required this.karat,
    required this.ratePerGram,
    required this.totalAmount,
    required this.pureGoldWeight,
    this.makingCharges = 0.0,
    this.taxAmount = 0.0,
    this.currency = 'Rs.',
    this.grossWeight = 0.0,
    this.stoneWeight = 0.0,
    this.discount = 0.0,
    this.lossPercent = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'weight': weight,
      'unit': unit,
      'karat': karat,
      'ratePerGram': ratePerGram,
      'totalAmount': totalAmount,
      'pureGoldWeight': pureGoldWeight,
      'makingCharges': makingCharges,
      'taxAmount': taxAmount,
      'currency': currency,
      'grossWeight': grossWeight,
      'stoneWeight': stoneWeight,
      'discount': discount,
      'lossPercent': lossPercent,
      'notes': notes,
    };
  }

  factory CalculationRecord.fromMap(Map<String, dynamic> map) {
    return CalculationRecord(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Gold Calculation',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      type: map['type'] ?? 'jewelry',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'g',
      karat: (map['karat'] as num?)?.toInt() ?? 24,
      ratePerGram: (map['ratePerGram'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      pureGoldWeight: (map['pureGoldWeight'] as num?)?.toDouble() ?? 0.0,
      makingCharges: (map['makingCharges'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'Rs.',
      grossWeight: (map['grossWeight'] as num?)?.toDouble() ?? 0.0,
      stoneWeight: (map['stoneWeight'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      lossPercent: (map['lossPercent'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CalculationRecord.fromJson(String source) =>
      CalculationRecord.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
