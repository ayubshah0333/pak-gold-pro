import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/gold_math.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Grams to TMR Controllers
  final TextEditingController _gramsInputController = TextEditingController(text: '11.664');

  // TMR to Grams Controllers
  final TextEditingController _tolaInputController = TextEditingController(text: '1');
  final TextEditingController _mashaInputController = TextEditingController(text: '0');
  final TextEditingController _rattiInputController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _gramsInputController.addListener(_onRefresh);
    _tolaInputController.addListener(_onRefresh);
    _mashaInputController.addListener(_onRefresh);
    _rattiInputController.addListener(_onRefresh);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gramsInputController.dispose();
    _tolaInputController.dispose();
    _mashaInputController.dispose();
    _rattiInputController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text(
              'Tola Masha Ratti Converter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Grams ➔ TMR'),
            Tab(text: 'TMR ➔ Grams'),
            Tab(text: 'Sarafa Table'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGramsToTmrTab(),
          _buildTmrToGramsTab(),
          _buildReferenceTableTab(),
        ],
      ),
    );
  }

  // TAB 1: Grams -> Tola Masha Ratti
  Widget _buildGramsToTmrTab() {
    final grams = double.tryParse(_gramsInputController.text) ?? 0.0;
    final tmr = GoldMath.gramsToTMR(grams);
    final totalTolas = grams / GoldMath.tolaInGrams;
    final totalMashas = grams / GoldMath.mashaInGrams;
    final totalRattis = grams / GoldMath.rattiInGrams;
    final troyOunces = grams / GoldMath.troyOunceInGrams;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Metric Weight (Grams)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gramsInputController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.scale, color: AppTheme.primaryGold),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                        onPressed: () => _gramsInputController.clear(),
                      ),
                      labelText: 'Weight in Grams',
                      suffixText: 'g',
                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick shortcut chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1.0, 5.0, 10.0, 11.664, 20.0, 50.0, 100.0, 116.64].map((preset) {
                      return ActionChip(
                        label: Text(
                          preset == 11.664 ? '1 Tola ($preset g)' : '$preset g',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppTheme.surfaceSecondary,
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        onPressed: () {
                          _gramsInputController.text = preset.toString();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary TMR Result Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.goldBannerGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGold, width: 1.5),
            ),
            child: Column(
              children: [
                const Text(
                  'TRADITIONAL SARAFA BREAKDOWN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTmrUnitPill('${tmr.tola}', 'TOLA'),
                    const Text('+', style: TextStyle(color: AppTheme.textMuted, fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildTmrUnitPill('${tmr.masha}', 'MASHA'),
                    const Text('+', style: TextStyle(color: AppTheme.textMuted, fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildTmrUnitPill(tmr.ratti.toStringAsFixed(2), 'RATTI'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.navyBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    tmr.formatted,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total Equivalent Metric Cards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full Unit Equivalents',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildConversionResultRow('Total Tolas:', '${totalTolas.toStringAsFixed(4)} Tola'),
                  _buildConversionResultRow('Total Mashas:', '${totalMashas.toStringAsFixed(3)} Masha'),
                  _buildConversionResultRow('Total Rattis:', '${totalRattis.toStringAsFixed(2)} Ratti'),
                  _buildConversionResultRow('Milligrams (mg):', '${(grams * 1000).toStringAsFixed(1)} mg'),
                  _buildConversionResultRow('Troy Ounces:', '${troyOunces.toStringAsFixed(4)} oz t'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Tola Masha Ratti -> Grams
  Widget _buildTmrToGramsTab() {
    final tola = double.tryParse(_tolaInputController.text) ?? 0.0;
    final masha = double.tryParse(_mashaInputController.text) ?? 0.0;
    final ratti = double.tryParse(_rattiInputController.text) ?? 0.0;

    final calculatedGrams = GoldMath.tmrToGrams(tola: tola, masha: masha, ratti: ratti);
    final calculatedMilligrams = calculatedGrams * 1000.0;
    final totalTolasDecimal = tola + (masha / 12.0) + (ratti / 96.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Tola, Masha & Ratti',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tolaInputController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          decoration: const InputDecoration(
                            labelText: 'Tola',
                            suffixText: 'T',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _mashaInputController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          decoration: const InputDecoration(
                            labelText: 'Masha',
                            suffixText: 'M',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _rattiInputController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          decoration: const InputDecoration(
                            labelText: 'Ratti',
                            suffixText: 'R',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _tolaInputController.text = '0';
                          _mashaInputController.text = '0';
                          _rattiInputController.text = '0';
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Output Result Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.goldBannerGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGold, width: 1.5),
            ),
            child: Column(
              children: [
                const Text(
                  'METRIC WEIGHT EQUIVALENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${calculatedGrams.toStringAsFixed(4)} Grams',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${calculatedMilligrams.toStringAsFixed(1)} Milligrams (mg)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.lightGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.navyBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    'Total Decimal Tolas: ${totalTolasDecimal.toStringAsFixed(4)} Tola',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Sarafa Reference Table
  Widget _buildReferenceTableTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table 1: Primary Traditional Sarafa Units
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: AppTheme.primaryGold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Standard Sarafa Scale (Pakistan)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTableRecord('1 Tola', '11.664 Grams (Exact 11.6638 g)'),
                  _buildTableRecord('1 Tola', '12 Masha'),
                  _buildTableRecord('1 Masha', '8 Ratti (0.972 Grams)'),
                  _buildTableRecord('1 Tola', '96 Ratti (12 × 8)'),
                  _buildTableRecord('1 Ratti', '0.1215 Grams (121.5 mg)'),
                  _buildTableRecord('1 Tola', '180 Grains (Rice/Wheat grain standard)'),
                  _buildTableRecord('1 Grain', '0.0648 Grams (64.8 mg)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Table 2: Modern & International Metric Reference
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: AppTheme.primaryGold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'International Gold Measurements',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTableRecord('10 Grams (Sona)', '0.85735 Tola'),
                  _buildTableRecord('1 Kilogram (1000g)', '85.735 Tolas'),
                  _buildTableRecord('1 Troy Ounce (oz t)', '31.1035 Grams (2.666 Tolas)'),
                  _buildTableRecord('1 Sovereign / Pavan', '8.000 Grams (0.6858 Tolas)'),
                  _buildTableRecord('1 Tola Biscuit', '116.64 g (Pack of 10 Tolas)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTmrUnitPill(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGold),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentGold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildConversionResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRecord(String unit, String equivalent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              unit,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              equivalent,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Aliasing for compatibility with existing imports
typedef ConverterScreen = UnitConverterScreen;
