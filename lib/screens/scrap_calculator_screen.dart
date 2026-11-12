import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/calculation_record.dart';
import '../services/ad_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../utils/gold_math.dart';

class ScrapCalculatorScreen extends StatefulWidget {
  final PreferencesService prefs;

  const ScrapCalculatorScreen({super.key, required this.prefs});

  @override
  State<ScrapCalculatorScreen> createState() => _ScrapCalculatorScreenState();
}

class _ScrapCalculatorScreenState extends State<ScrapCalculatorScreen> {
  late TextEditingController _rate24kTolaController;
  final TextEditingController _grossWeightController = TextEditingController(text: '15.0');
  final TextEditingController _stoneWeightController = TextEditingController(text: '1.2');
  final TextEditingController _katanLossController = TextEditingController(text: '2.0');
  final TextEditingController _customerNameController = TextEditingController(text: 'Customer Old Gold');

  int _selectedKarat = 22;
  String _katanMode = '%'; // '%' or 'g' (grams)


  @override
  void initState() {
    super.initState();
    _rate24kTolaController = TextEditingController(
      text: widget.prefs.sarafaRate24kTola.toStringAsFixed(0),
    );

    _rate24kTolaController.addListener(_recalculate);
    _grossWeightController.addListener(_recalculate);
    _stoneWeightController.addListener(_recalculate);
    _katanLossController.addListener(_recalculate);
    _customerNameController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _rate24kTolaController.dispose();
    _grossWeightController.dispose();
    _stoneWeightController.dispose();
    _katanLossController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {});
  }

  double get _rate24kTola => double.tryParse(_rate24kTolaController.text) ?? 0.0;
  double get _grossWeight => double.tryParse(_grossWeightController.text) ?? 0.0;
  double get _stoneWeight => double.tryParse(_stoneWeightController.text) ?? 0.0;
  double get _katanInput => double.tryParse(_katanLossController.text) ?? 0.0;

  double get _netGoldGrams => (_grossWeight - _stoneWeight).clamp(0.0, double.infinity);
  double get _purity => GoldMath.getPurityMultiplier(_selectedKarat);
  double get _pureGoldWeight => _netGoldGrams * _purity;

  double get _lossGrams {
    if (_katanMode == '%') {
      return _pureGoldWeight * (_katanInput / 100.0);
    } else {
      return _katanInput.clamp(0.0, _pureGoldWeight);
    }
  }

  double get _payableGoldWeight => (_pureGoldWeight - _lossGrams).clamp(0.0, double.infinity);
  double get _rate24kPerGram => _rate24kTola > 0 ? _rate24kTola / GoldMath.tolaInGrams : 0.0;
  double get _scrapPayout => _payableGoldWeight * _rate24kPerGram;

  String _formatPkr(double amount) {
    final formatter = NumberFormat('#,##,###');
    return 'Rs. ${formatter.format(amount.round())}';
  }

  String _generateScrapParchText() {
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final tmr = GoldMath.gramsToTMR(_netGoldGrams);
    final title = _customerNameController.text.trim().isEmpty ? 'Old Gold / Scrap Melter' : _customerNameController.text.trim();
    final shopTitle = widget.prefs.shopName.trim().isNotEmpty
        ? widget.prefs.shopName.trim().toUpperCase()
        : 'PAK GOLD PRO — OLD GOLD / SCRAP PARCH';
    final shopSubtitle = widget.prefs.shopContact.trim().isNotEmpty
        ? '\n📞 *Rabta:* ${widget.prefs.shopContact.trim()}'
        : '';

    return '''
🌟 *$shopTitle* 🌟$shopSubtitle
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 *Tareekh:* $now
👤 *Reference:* $title
👑 *Gold Karat:* $_selectedKarat K (${GoldMath.getHallmarkLabel(_selectedKarat)})
💰 *24K Tola Rate:* ${_formatPkr(_rate24kTola)}
📈 *Pure Gold Rate/g:* ${_formatPkr(_rate24kPerGram)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ *Kul Wazan (Gross):* ${_grossWeight.toStringAsFixed(3)} g
💎 *Nageena (Stone):* ${_stoneWeight.toStringAsFixed(3)} g
✨ *Safi Wazan (Net):* ${_netGoldGrams.toStringAsFixed(3)} g
🏷️ *Tola/Masha/Ratti:* ${tmr.formatted}
🪙 *Khalis Sona (Pure 24K):* ${_pureGoldWeight.toStringAsFixed(3)} g
🔥 *Katan / Katoti (${_katanMode == '%' ? '$_katanInput%' : '${_katanInput}g'}):* ${_lossGrams.toStringAsFixed(3)} g
⚖️ *Payable Gold Weight:* ${_payableGoldWeight.toStringAsFixed(3)} g
════════════════════════════
💵 *KUL CASH PAYOUT (Raqam):* ${_formatPkr(_scrapPayout)}
════════════════════════════
✨ *Pak Gold Pro — Digital Sarafa Bahi-Khata*''';
  }

  Future<void> _sendWhatsAppParch() async {
    final text = _generateScrapParchText();
    final urlString = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
    final fallbackUrl = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';

    final nativeUri = Uri.parse(urlString);
    final webUri = Uri.parse(fallbackUrl);

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp not detected. Scrap Parch copied to Clipboard!'),
              backgroundColor: AppTheme.accentGold,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parch copied to Clipboard!'),
            backgroundColor: AppTheme.primaryGold,
          ),
        );
      }
    }
  }

  Future<void> _saveScrapCalculation() async {
    final count = await widget.prefs.incrementCalculationCount();
    if (count % 3 == 0) {
      AdService.showInterstitialAdIfReady();
    }

    final title = _customerNameController.text.trim().isEmpty ? 'Old Gold / Scrap' : _customerNameController.text.trim();

    final record = CalculationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '$title (${_grossWeight.toStringAsFixed(2)}g, $_selectedKarat K)',
      timestamp: DateTime.now(),
      type: 'scrap',
      weight: _netGoldGrams,
      unit: 'g',
      karat: _selectedKarat,
      ratePerGram: _rate24kPerGram,
      totalAmount: _scrapPayout,
      pureGoldWeight: _payableGoldWeight,
      currency: 'Rs.',
      grossWeight: _grossWeight,
      stoneWeight: _stoneWeight,
      lossPercent: _katanMode == '%' ? _katanInput : (_lossGrams / _pureGoldWeight) * 100.0,
      notes: 'Katan deduction: ${_lossGrams.toStringAsFixed(3)} g',
    );

    await widget.prefs.addHistoryRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Old gold estimation saved to History!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyBreakdown() {
    Clipboard.setData(ClipboardData(text: _generateScrapParchText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scrap Parch copied to Clipboard!'),
        backgroundColor: AppTheme.primaryGold,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCustomKaratDialog() {
    final controller = TextEditingController(text: _selectedKarat.toString());
    int tempKarat = _selectedKarat;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final purity = (GoldMath.getPurityMultiplier(tempKarat) * 100);
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: AppTheme.primaryGold),
                  SizedBox(width: 8),
                  Text(
                    'Custom Scrap Karat',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer se low quality ya antique purana sona khareedne ke liye Karat (1K to 24K) darj karein:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Gold Karat (K)',
                      suffixText: 'Karat',
                      prefixIcon: Icon(Icons.workspace_premium, color: AppTheme.primaryGold),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 1 && parsed <= 24) {
                        setDialogState(() {
                          tempKarat = parsed;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Calculated Purity:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(
                          '${tempKarat}K = ${purity.toStringAsFixed(1)}% Pure',
                          style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final k = int.tryParse(controller.text) ?? tempKarat;
                    if (k >= 1 && k <= 24) {
                      setState(() {
                        _selectedKarat = k;
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Apply Karat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScrapKaratTile(int k) {
    final isSelected = _selectedKarat == k;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedKarat = k;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryGold : AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.accentGold : AppTheme.borderSubtle,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${k}K',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(GoldMath.getPurityMultiplier(k) * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black87 : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tmr = GoldMath.gramsToTMR(_netGoldGrams);

    return Scaffold(
      backgroundColor: AppTheme.navyBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.recycling_rounded, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text(
              'Old Gold / Scrap Melter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.primaryGold),
            tooltip: 'Copy Scrap Parch',
            onPressed: _copyBreakdown,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer & Rate Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer / Voucher Reference',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryGold, size: 20),
                        hintText: 'e.g. Hajji Tariq / Churi Tukray',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _rate24kTolaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Current 24K Rate / Tola (PKR)',
                        prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppTheme.primaryGold, size: 20),
                        suffixText: 'PKR',
                        suffixStyle: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                        helperText: 'Pure Gold: ${_formatPkr(_rate24kPerGram)}/g',
                        helperStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Karat Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Purity / Karat',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _selectedKarat < 18 ? const Color(0x33F59E0B) : const Color(0x33D4AF37),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _selectedKarat < 18 ? const Color(0xFFF59E0B) : AppTheme.primaryGold,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${_selectedKarat}K • ${(GoldMath.getPurityMultiplier(_selectedKarat) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _selectedKarat < 18 ? const Color(0xFFFFD54F) : AppTheme.accentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 1: High Karats (Standard Sarafa)
                    Row(
                      children: [24, 22, 21, 18].map((k) => _buildScrapKaratTile(k)).toList(),
                    ),
                    const SizedBox(height: 7),
                    // Row 2: Low & Antique Karats (16K, 14K, 12K, 10K)
                    Row(
                      children: [16, 14, 12, 10].map((k) => _buildScrapKaratTile(k)).toList(),
                    ),
                    const SizedBox(height: 7),
                    // Row 3: 9K + Custom Karat button
                    Row(
                      children: [
                        _buildScrapKaratTile(9),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: _showCustomKaratDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                              decoration: BoxDecoration(
                                color: (![24, 22, 21, 18, 16, 14, 12, 10, 9].contains(_selectedKarat))
                                    ? AppTheme.primaryGold
                                    : AppTheme.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (![24, 22, 21, 18, 16, 14, 12, 10, 9].contains(_selectedKarat))
                                      ? AppTheme.accentGold
                                      : AppTheme.borderSubtle,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 15,
                                    color: (![24, 22, 21, 18, 16, 14, 12, 10, 9].contains(_selectedKarat))
                                        ? Colors.black
                                        : AppTheme.accentGold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (![24, 22, 21, 18, 16, 14, 12, 10, 9].contains(_selectedKarat))
                                        ? 'Custom: ${_selectedKarat}K (${(GoldMath.getPurityMultiplier(_selectedKarat) * 100).toStringAsFixed(1)}%)'
                                        : '+ Custom Karat (1K - 23K)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: (![24, 22, 21, 18, 16, 14, 12, 10, 9].contains(_selectedKarat))
                                          ? Colors.black
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Weights & Katoti Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _grossWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Kul Wazan (Gross g)',
                              prefixIcon: Icon(Icons.scale, color: AppTheme.primaryGold, size: 20),
                              suffixText: 'g',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _stoneWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Nageena (Stone g)',
                              prefixIcon: Icon(Icons.diamond_outlined, color: AppTheme.accentGold, size: 20),
                              suffixText: 'g',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _katanLossController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Katan / Melting Loss ($_katanMode)',
                              prefixIcon: const Icon(Icons.local_fire_department, color: AppTheme.alertRed, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Mode switch (% vs g)
                        Row(
                          children: [
                            _buildKatanModeChip('%', 'Percent (%)'),
                            const SizedBox(width: 4),
                            _buildKatanModeChip('g', 'Grams (g)'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.infoBlue, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Safi Wazan: ${_netGoldGrams.toStringAsFixed(3)} g (${tmr.formatted})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scrap Melter Breakdown & Cash Payout Card
            _buildPayoutCard(tmr),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKatanModeChip(String mode, String label) {
    final isSelected = _katanMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _katanMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutCard(TmrBreakdown tmr) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33D4AF37),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.prefs.shopName.trim().isNotEmpty
                          ? widget.prefs.shopName.trim().toUpperCase()
                          : 'OLD GOLD VALUATION PARCH',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_selectedKarat}K Scrap',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow('Kul Wazan (Gross):', '${_grossWeight.toStringAsFixed(3)} g'),
                _buildRow('Nageena (Stone deduction):', '- ${_stoneWeight.toStringAsFixed(3)} g'),
                _buildRow('Safi Wazan (Net Gold):', '${_netGoldGrams.toStringAsFixed(3)} g', isBold: true),
                _buildRow('Pure Gold Equivalent (24K):', '${_pureGoldWeight.toStringAsFixed(3)} g'),
                _buildRow(
                  'Katan / Melting Loss deduction:',
                  '- ${_lossGrams.toStringAsFixed(3)} g',
                  isDeduction: true,
                ),
                const Divider(color: AppTheme.borderSubtle, height: 16),
                _buildRow(
                  'Payable Net Pure Gold:',
                  '${_payableGoldWeight.toStringAsFixed(3)} g',
                  isBold: true,
                ),
                _buildRow('24K Rate / Gram:', '${_formatPkr(_rate24kPerGram)} / g'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KUL CASH PAYOUT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Customer Net Adaigi',
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      Text(
                        _formatPkr(_scrapPayout),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accentGold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? AppTheme.textPrimary : AppTheme.textMuted,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDeduction
                  ? AppTheme.alertRed
                  : isBold
                      ? AppTheme.accentGold
                      : AppTheme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _sendWhatsAppParch,
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            label: const Text(
              'WhatsApp Par Parch Bhejein',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveScrapCalculation,
                  icon: const Icon(Icons.bookmark_add, color: Color(0xFF0A1220)),
                  label: const Text('Save Parch'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _copyBreakdown,
                  icon: const Icon(Icons.copy, color: AppTheme.primaryGold),
                  label: const Text(
                    'Copy Text',
                    style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
