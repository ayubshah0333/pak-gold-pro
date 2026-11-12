import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/calculation_record.dart';
import '../services/ad_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../utils/gold_math.dart';

class JewelryCalculatorScreen extends StatefulWidget {
  final PreferencesService prefs;

  const JewelryCalculatorScreen({super.key, required this.prefs});

  @override
  State<JewelryCalculatorScreen> createState() => _JewelryCalculatorScreenState();
}

class _JewelryCalculatorScreenState extends State<JewelryCalculatorScreen> {
  // Input controllers
  late TextEditingController _rate24kTolaController;
  final TextEditingController _grossWeightController = TextEditingController(text: '12.5');
  final TextEditingController _stoneWeightController = TextEditingController(text: '0.5');
  final TextEditingController _makingController = TextEditingController(text: '2500');
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _itemNameController = TextEditingController(text: 'Gold Bangle');

  int _selectedKarat = 22;
  String _makingMode = 'flat'; // 'flat' (Rs. flat), 'per_gram' (Rs./g), 'percent' (%)


  @override
  void initState() {
    super.initState();
    _rate24kTolaController = TextEditingController(
      text: widget.prefs.sarafaRate24kTola.toStringAsFixed(0),
    );

    _rate24kTolaController.addListener(_onChanged);
    _grossWeightController.addListener(_onChanged);
    _stoneWeightController.addListener(_onChanged);
    _makingController.addListener(_onChanged);
    _discountController.addListener(_onChanged);
    _itemNameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _rate24kTolaController.dispose();
    _grossWeightController.dispose();
    _stoneWeightController.dispose();
    _makingController.dispose();
    _discountController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  // Numerical parsers
  double get _rate24kTola => double.tryParse(_rate24kTolaController.text) ?? 0.0;
  double get _grossGrams => double.tryParse(_grossWeightController.text) ?? 0.0;
  double get _stoneGrams => double.tryParse(_stoneWeightController.text) ?? 0.0;
  double get _makingInput => double.tryParse(_makingController.text) ?? 0.0;
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;

  // Calculation logic
  double get _netGoldGrams => (_grossGrams - _stoneGrams).clamp(0.0, double.infinity);
  double get _karatPurity => GoldMath.getPurityMultiplier(_selectedKarat);
  double get _pureGoldGrams => _netGoldGrams * _karatPurity;

  // 1 tola = 11.6638038 grams
  double get _rate24kPerGram => _rate24kTola > 0 ? _rate24kTola / GoldMath.tolaInGrams : 0.0;
  double get _karatRatePerGram => _rate24kPerGram * _karatPurity;
  double get _baseGoldValue => _netGoldGrams * _karatRatePerGram;

  double get _makingAmount {
    if (_makingMode == 'percent') {
      return _baseGoldValue * (_makingInput / 100.0);
    } else if (_makingMode == 'per_gram') {
      return _makingInput * _netGoldGrams;
    } else {
      return _makingInput; // Flat PKR
    }
  }

  double get _totalPayable => (_baseGoldValue + _makingAmount - _discount).clamp(0.0, double.infinity);

  String _formatPkr(double amount) {
    final formatter = NumberFormat('#,##,###');
    return 'Rs. ${formatter.format(amount.round())}';
  }

  String _generateParchText() {
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final tmr = GoldMath.gramsToTMR(_netGoldGrams);
    final itemName = _itemNameController.text.trim().isEmpty ? 'Gold Jewelry' : _itemNameController.text.trim();
    final shopTitle = widget.prefs.shopName.trim().isNotEmpty
        ? widget.prefs.shopName.trim().toUpperCase()
        : 'PAK GOLD PRO — SARAFA BILL / PARCH';
    final shopSubtitle = widget.prefs.shopContact.trim().isNotEmpty
        ? '\n📞 *Rabta:* ${widget.prefs.shopContact.trim()}'
        : '';

    return '''
🌟 *$shopTitle* 🌟$shopSubtitle
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 *Tareekh:* $now
💍 *Item:* $itemName
👑 *Gold Karat:* $_selectedKarat K (${GoldMath.getHallmarkLabel(_selectedKarat)})
💰 *24K Tola Rate:* ${_formatPkr(_rate24kTola)}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ *Kul Wazan (Gross):* ${_grossGrams.toStringAsFixed(3)} g
💎 *Nageena (Stone):* ${_stoneGrams.toStringAsFixed(3)} g
✨ *Safi Sona (Net):* ${_netGoldGrams.toStringAsFixed(3)} g
🏷️ *Tola/Masha/Ratti:* ${tmr.formatted}
🪙 *Khalis Sona (Pure):* ${_pureGoldGrams.toStringAsFixed(3)} g
📈 *Pure Gold Rate/g:* ${_formatPkr(_karatRatePerGram)} / g
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💵 *Soney Ki Qeemat:* ${_formatPkr(_baseGoldValue)}
🔨 *Mazdoori (Making):* ${_formatPkr(_makingAmount)}
🏷️ *Discount (Riaayat):* ${_formatPkr(_discount)}
════════════════════════════
🏆 *KUL PAYABLE RAQAM:* ${_formatPkr(_totalPayable)}
════════════════════════════
✨ *Pak Gold Pro — Digital Sarafa Bahi-Khata*''';
  }

  Future<void> _sendWhatsAppParch() async {
    final text = _generateParchText();
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
              content: Text('WhatsApp not detected. Parch copied to Clipboard!'),
              backgroundColor: AppTheme.accentGold,
            ),
          );
        }
      }
    } catch (e) {
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

  Future<void> _saveParch() async {
    final count = await widget.prefs.incrementCalculationCount();
    if (count % 3 == 0) {
      AdService.showInterstitialAdIfReady();
    }

    final itemName = _itemNameController.text.trim().isEmpty ? 'Gold Jewelry' : _itemNameController.text.trim();

    final record = CalculationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '$itemName ($_selectedKarat K, ${_netGoldGrams.toStringAsFixed(2)}g)',
      timestamp: DateTime.now(),
      type: 'jewelry',
      weight: _netGoldGrams,
      unit: 'g',
      karat: _selectedKarat,
      ratePerGram: _karatRatePerGram,
      totalAmount: _totalPayable,
      pureGoldWeight: _pureGoldGrams,
      makingCharges: _makingAmount,
      taxAmount: 0.0,
      currency: 'Rs.',
      grossWeight: _grossGrams,
      stoneWeight: _stoneGrams,
      discount: _discount,
      lossPercent: 0.0,
      notes: 'Rate 24K: ${_formatPkr(_rate24kTola)}/tola',
    );

    await widget.prefs.addHistoryRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Parch saved to History! (ID: ${record.id.substring(record.id.length - 4)})'),
              ),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyParch() {
    Clipboard.setData(ClipboardData(text: _generateParchText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parch copied to Clipboard!'),
        backgroundColor: AppTheme.primaryGold,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetFields() {
    setState(() {
      _grossWeightController.text = '10.0';
      _stoneWeightController.text = '0.0';
      _makingController.text = '0';
      _discountController.text = '0';
      _itemNameController.text = 'Gold Jewelry';
      _selectedKarat = 22;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tmr = GoldMath.gramsToTMR(_netGoldGrams);

    return Scaffold(
      backgroundColor: AppTheme.navyBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text(
              'Jewelry Parch & Bill',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted),
            tooltip: 'Reset Form',
            onPressed: _resetFields,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.primaryGold),
            tooltip: 'Copy Parch Text',
            onPressed: _copyParch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item description & 24K Rate Bar
            _buildRateAndItemCard(),
            const SizedBox(height: 12),

            // Karat Selector Card
            _buildKaratSelectorCard(),
            const SizedBox(height: 12),

            // Weight & Stone Inputs Card
            _buildWeightsCard(tmr),
            const SizedBox(height: 12),

            // Making Charges (Mazdoori) & Discount Card
            _buildMakingAndDiscountCard(),
            const SizedBox(height: 16),

            // Live Invoice Summary / Parch Card
            _buildLiveInvoiceCard(tmr),
            const SizedBox(height: 16),

            // Action Buttons: WhatsApp Parch & Save Parch
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRateAndItemCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name / Zewar',
                      prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGold, size: 20),
                      hintText: 'e.g. Choorian, Kangan, Haar',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rate24kTolaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '24K Rate / Tola (PKR)',
                      prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppTheme.primaryGold, size: 20),
                      suffixText: 'PKR',
                      suffixStyle: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                      helperText: 'Per gram: ${_formatPkr(_rate24kPerGram)}',
                      helperStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    'Custom Gold Karat',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer se low quality ya antique gold khareedne ke liye Karat (1K to 24K) darj karein:',
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

  Widget _buildKaratTile(int k) {
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

  Widget _buildKaratSelectorCard() {
    final isCustom = ![24, 22, 21, 18, 16, 14, 12, 10, 9].contains(_selectedKarat);
    return Card(
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
                    'Select Gold Karat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
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
            // Row 1: High Karats (Sarafa Standards)
            Row(
              children: [24, 22, 21, 18].map((k) => _buildKaratTile(k)).toList(),
            ),
            const SizedBox(height: 7),
            // Row 2: Low Karats (16K, 14K, 12K, 10K)
            Row(
              children: [16, 14, 12, 10].map((k) => _buildKaratTile(k)).toList(),
            ),
            const SizedBox(height: 7),
            // Row 3: 9K + Custom Karat button
            Row(
              children: [
                _buildKaratTile(9),
                const SizedBox(width: 5),
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _showCustomKaratDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isCustom ? AppTheme.primaryGold : AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCustom ? AppTheme.accentGold : AppTheme.borderSubtle,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 15,
                            color: isCustom ? Colors.black : AppTheme.accentGold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCustom
                                ? 'Custom: ${_selectedKarat}K (${(GoldMath.getPurityMultiplier(_selectedKarat) * 100).toStringAsFixed(1)}%)'
                                : '+ Custom Karat (1K - 23K)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isCustom ? Colors.black : AppTheme.textPrimary,
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
    );
  }

  Widget _buildWeightsCard(TmrBreakdown tmr) {
    return Card(
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
                const SizedBox(width: 12),
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
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safi Wazan (Net): ${_netGoldGrams.toStringAsFixed(3)} g  •  ${tmr.formatted}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMakingAndDiscountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mazdoori & Discount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                // Making mode selector
                Row(
                  children: [
                    _buildModeChip('flat', 'Rs. Flat'),
                    const SizedBox(width: 4),
                    _buildModeChip('per_gram', 'Rs./g'),
                    const SizedBox(width: 4),
                    _buildModeChip('percent', '%'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Mazdoori (${_makingMode == 'percent' ? '%' : 'PKR'})',
                      prefixIcon: const Icon(Icons.handyman_outlined, color: AppTheme.primaryGold, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Discount (PKR)',
                      prefixIcon: Icon(Icons.discount_outlined, color: AppTheme.successGreen, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode, String label) {
    final isSelected = _makingMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _makingMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildLiveInvoiceCard(TmrBreakdown tmr) {
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
          // Parch Header
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
                    const Icon(Icons.verified, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.prefs.shopName.trim().isNotEmpty
                          ? widget.prefs.shopName.trim().toUpperCase()
                          : 'SARAFA PARCH / BILL',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_selectedKarat}K (${(GoldMath.getPurityMultiplier(_selectedKarat) * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Parch Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInvoiceRow('Kul Wazan (Gross):', '${_grossGrams.toStringAsFixed(3)} g'),
                _buildInvoiceRow('Nageena / Stone:', '- ${_stoneGrams.toStringAsFixed(3)} g'),
                const Divider(color: AppTheme.borderSubtle, height: 16),
                _buildInvoiceRow('Safi Sona (Net Gold):', '${_netGoldGrams.toStringAsFixed(3)} g', isBold: true),
                _buildInvoiceRow('Tola / Masha / Ratti:', tmr.formatted),
                _buildInvoiceRow('Khalis Sona (Pure 24K):', '${_pureGoldGrams.toStringAsFixed(3)} g'),
                _buildInvoiceRow('Pure Gold Rate/g:', '${_formatPkr(_karatRatePerGram)} / g'),
                const Divider(color: AppTheme.borderSubtle, height: 16),
                _buildInvoiceRow('Soney Ki Qeemat:', _formatPkr(_baseGoldValue)),
                if (_makingAmount > 0)
                  _buildInvoiceRow('Mazdoori (Making):', '+ ${_formatPkr(_makingAmount)}'),
                if (_discount > 0)
                  _buildInvoiceRow('Discount (Riaayat):', '- ${_formatPkr(_discount)}', isDiscount: true),
                const SizedBox(height: 8),
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
                            'KUL PAYABLE RAQAM',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Total Net Payable',
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      Text(
                        _formatPkr(_totalPayable),
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

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
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
              color: isDiscount
                  ? AppTheme.successGreen
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
              backgroundColor: const Color(0xFF25D366), // WhatsApp Brand Green
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
                  onPressed: _saveParch,
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
                  onPressed: _copyParch,
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

// Aliasing for compatibility with existing imports
typedef CalculatorScreen = JewelryCalculatorScreen;
