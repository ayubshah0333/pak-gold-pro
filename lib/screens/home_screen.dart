import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/preferences_service.dart';
import '../services/gold_rate_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import 'history_screen.dart';
import 'jewelry_calculator_screen.dart';
import 'scrap_calculator_screen.dart';
import 'unit_converter_screen.dart';

class GoldHomeScreen extends StatefulWidget {
  final PreferencesService prefs;

  const GoldHomeScreen({super.key, required this.prefs});

  @override
  State<GoldHomeScreen> createState() => _GoldHomeScreenState();
}

class _GoldHomeScreenState extends State<GoldHomeScreen> {
  int _currentIndex = 0;
  double _rate24K = 428700.0;
  String _lastUpdated = 'Loading rates...';
  bool _isSyncing = false;
  final NumberFormat _currency = NumberFormat("#,##0", "en_US");

  @override
  void initState() {
    super.initState();
    _rate24K = widget.prefs.sarafaRate24kTola;
    _lastUpdated = widget.prefs.sarafaLastUpdated;
    _autoSyncRates(); // App khulte hi automatically rate update hoga
  }

  // Auto-Sync Logic (Online + Offline Cache)
  Future<void> _autoSyncRates() async {
    setState(() => _isSyncing = true);

    final result = await GoldRateService.fetchLiveRate();

    if (mounted) {
      final double fetchedRate = (result['rate'] as num).toDouble();
      final String fetchedDate = (result['date'] as String?) ?? 'Today (Cached)';
      final bool isLive = result['isLive'] as bool? ?? false;

      await widget.prefs.updateSarafaRates(
        rate24kTola: fetchedRate,
      );

      setState(() {
        _rate24K = fetchedRate;
        _lastUpdated = fetchedDate;
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLive
                  ? 'Sarafa Rates updated live! (Rs. ${_currency.format(fetchedRate)})'
                  : 'Sarafa Rates loaded: Rs. ${_currency.format(fetchedRate)}',
            ),
            backgroundColor: isLive ? AppTheme.successGreen : AppTheme.cardBg,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updateRateDialog() async {
    final ctrl = TextEditingController(text: _rate24K.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
        ),
        title: const Text('Sarafa Rate Update Karein', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            labelText: '24K Pure Gold Rate (Per Tola PKR)',
            border: OutlineInputBorder(),
            prefixText: 'Rs. ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRate = double.tryParse(ctrl.text) ?? _rate24K;
              await widget.prefs.updateSarafaRates(rate24kTola: newRate);
              setState(() {
                _rate24K = newRate;
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardView(
            prefs: widget.prefs,
            isSyncing: _isSyncing,
            lastUpdated: _lastUpdated,
            onSync: _autoSyncRates,
            onEditRate: _updateRateDialog,
            onNavigateToTab: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          JewelryCalculatorScreen(prefs: widget.prefs),
          ScrapCalculatorScreen(prefs: widget.prefs),
          const UnitConverterScreen(),
          HistoryScreen(prefs: widget.prefs),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Jewelry',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.recycling_outlined),
                activeIcon: Icon(Icons.recycling),
                label: 'Old Gold',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.swap_horiz_outlined),
                activeIcon: Icon(Icons.swap_horiz),
                label: 'Converter',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_edu_outlined),
                activeIcon: Icon(Icons.history_edu),
                label: 'History',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Aliasing for backwards-compatibility
typedef HomeScreen = GoldHomeScreen;

class _DashboardView extends StatelessWidget {
  final PreferencesService prefs;
  final ValueChanged<int> onNavigateToTab;
  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback onEditRate;
  final String? lastUpdated;

  const _DashboardView({
    required this.prefs,
    required this.onNavigateToTab,
    this.isSyncing = false,
    required this.onSync,
    required this.onEditRate,
    this.lastUpdated,
  });

  String _formatPkr(double amount) {
    final formatter = NumberFormat('#,##,###');
    return 'Rs. ${formatter.format(amount.round())}';
  }

  void _showShopProfileDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: prefs.shopName);
    final contactCtrl = TextEditingController(text: prefs.shopContact);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final previewName = nameCtrl.text.trim().isEmpty ? 'YOUR SHOP NAME' : nameCtrl.text.trim().toUpperCase();
          final previewContact = contactCtrl.text.trim();

          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.storefront_rounded, color: AppTheme.primaryGold),
                SizedBox(width: 8),
                Text(
                  'Shop / Jeweller Profile',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apna ya apni dukan ka naam likhein taake tamam WhatsApp parch aur raseedon par aapki dukan ka naam aaye:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                    decoration: const InputDecoration(
                      labelText: 'Dukan / Jeweller Name *',
                      hintText: 'e.g. Al-Makkah Jewellers',
                      prefixIcon: Icon(Icons.store, color: AppTheme.primaryGold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Phone / City (Optional)',
                      hintText: 'e.g. 0300-1234567 • Peshawar',
                      prefixIcon: Icon(Icons.phone, color: AppTheme.primaryGold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Parch / Raseed Preview:',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🌟 $previewName 🌟',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 13),
                        ),
                        if (previewContact.isNotEmpty)
                          Text(
                            '📞 Rabta: $previewContact',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        const Text(
                          '━━━━━━━━━━━━━━━━━━━━',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                        const Text(
                          '💍 Item: Gold Jewelry\n👑 Karat: 22K\n🏆 KUL PAYABLE: Rs. ...',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                onPressed: () async {
                  await prefs.updateShopProfile(
                    name: nameCtrl.text,
                    contact: contactCtrl.text,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shop Profile saved! Ab raseedon par aapki dukan ka naam aayega.'),
                        backgroundColor: AppTheme.successGreen,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                label: const Text('Save Profile'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRateDialog(BuildContext context) {
    final controller = TextEditingController(
      text: prefs.sarafaRate24kTola.toStringAsFixed(0),
    );
    String selectedCity = prefs.sarafaMarketCity;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_note, color: AppTheme.primaryGold),
                  SizedBox(width: 8),
                  Text(
                    'Update Sarafa Rate',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter current market rate for 24K Gold per Tola:',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                      decoration: const InputDecoration(
                        labelText: '24K Per Tola (PKR)',
                        prefixIcon: Icon(Icons.monetization_on, color: AppTheme.primaryGold),
                        suffixText: 'PKR',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Market Center:',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        'Karachi / Lahore',
                        'Karachi Sarafa',
                        'Lahore Sarafa',
                        'Peshawar Sarafa',
                        'Rawalpindi / ISB',
                        'Multan Sarafa',
                        'Quetta Sarafa',
                      ].map((city) {
                        final isSelected = selectedCity == city;
                        return ChoiceChip(
                          label: Text(city, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : AppTheme.textPrimary)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGold,
                          backgroundColor: AppTheme.surfaceSecondary,
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                selectedCity = city;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newRate = double.tryParse(controller.text) ?? prefs.sarafaRate24kTola;
                    await prefs.updateSarafaRates(rate24kTola: newRate, city: selectedCity);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sarafa Rate updated successfully!'),
                          backgroundColor: AppTheme.successGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Rate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final rate24kTola = prefs.sarafaRate24kTola;
        final rate22kTola = prefs.sarafaRate22kTola;
        final rate24k10g = prefs.sarafaRate24k10g;
        final rate22k10g = prefs.sarafaRate22k10g;
        final bannerLastUpdated = (lastUpdated != null && lastUpdated!.isNotEmpty)
            ? lastUpdated!
            : prefs.sarafaLastUpdated;
        final city = prefs.sarafaMarketCity;

        return Scaffold(
          backgroundColor: AppTheme.navyBg,
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.monetization_on, color: AppTheme.navyBg),
                    );
                  },
                ),
              ),
            ),
            title: const Text(
              'Pak Gold Pro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            actions: [
              isSyncing
                  ? const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFB8860B),
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Sync Rate',
                      icon: const Icon(Icons.refresh_rounded, size: 26, color: Color(0xFFB8860B)),
                      onPressed: onSync,
                    ),
              IconButton(
                tooltip: 'Shop Profile / Dukan Name',
                icon: const Icon(Icons.storefront_rounded, size: 24, color: AppTheme.accentGold),
                onPressed: () => _showShopProfileDialog(context),
              ),
              IconButton(
                tooltip: 'Manual Edit',
                icon: const Icon(Icons.edit_note_rounded, size: 28, color: Color(0xFFB8860B)),
                onPressed: () => _showEditRateDialog(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner: Sarafa Rates Banner with Gold Gradient & Edit Trigger
                _buildSarafaBanner(
                  context: context,
                  city: city,
                  lastUpdated: bannerLastUpdated,
                  rate24kTola: rate24kTola,
                  rate22kTola: rate22kTola,
                  rate24k10g: rate24k10g,
                  rate22k10g: rate22k10g,
                ),
                const SizedBox(height: 12),

                // Jeweller / Shop Profile Card
                _buildShopProfileCard(context),
                const SizedBox(height: 16),

                // Market Purity Breakdown Card
                _buildMarketPurityCard(),
                const SizedBox(height: 18),

                // Section Title: Shopkeeper & Buyer Tools
                const Row(
                  children: [
                    Icon(Icons.handyman_rounded, color: AppTheme.primaryGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Shopkeeper & Buyer Tools',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tool Card 1: Jewelry Purchase & Bill Calculator
                _buildToolCard(
                  context: context,
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppTheme.primaryGold,
                  title: 'Jewelry Purchase & Bill Calculator',
                  subtitle: 'Kul Wazan, Nageena, Mazdoori, Karat & WhatsApp Parch',
                  badge: 'Most Popular',
                  badgeColor: AppTheme.primaryGold,
                  onTap: () => onNavigateToTab(1),
                ),
                const SizedBox(height: 10),

                // Tool Card 2: Tola Masha Ratti Grams Converter
                _buildToolCard(
                  context: context,
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppTheme.accentGold,
                  title: 'Tola Masha Ratti Converter',
                  subtitle: 'Bidirectional Metric Grams ⮂ Tola, Masha & Ratti',
                  badge: 'Traditional Scale',
                  badgeColor: AppTheme.accentGold,
                  onTap: () => onNavigateToTab(3),
                ),
                const SizedBox(height: 10),

                // Tool Card 3: Old Gold / Scrap Melter
                _buildToolCard(
                  context: context,
                  icon: Icons.recycling_rounded,
                  iconColor: const Color(0xFFF87171),
                  title: 'Old Gold / Scrap Melter',
                  subtitle: 'Katan & Katoti Deduction, Melting Loss & Cash Payout',
                  badge: 'Buying Desk',
                  badgeColor: const Color(0xFFF87171),
                  onTap: () => onNavigateToTab(2),
                ),
                const SizedBox(height: 10),

                // Tool Card 4: Saved Parch / Invoice History
                _buildToolCard(
                  context: context,
                  icon: Icons.history_edu_rounded,
                  iconColor: AppTheme.infoBlue,
                  title: 'Saved Parch & Bill History',
                  subtitle: 'Access Past Receipts, WhatsApp Sharing & Records',
                  badge: '${prefs.history.length} Saved',
                  badgeColor: AppTheme.infoBlue,
                  onTap: () => onNavigateToTab(4),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopProfileCard(BuildContext context) {
    final hasShop = prefs.shopName.isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasShop ? AppTheme.primaryGold.withValues(alpha: 0.6) : AppTheme.surfaceBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showShopProfileDialog(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryGold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasShop ? prefs.shopName : 'Apni Dukan Ka Naam Set Karein',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: hasShop ? AppTheme.accentGold : AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasShop
                          ? (prefs.shopContact.isNotEmpty ? prefs.shopContact : 'Raseedon aur WhatsApp Parch par yehi naam aayega')
                          : 'Raseedon aur Parch par dukan ka naam lagane ke liye tap karein',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasShop ? AppTheme.surfaceSecondary : AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasShop ? Icons.edit_note : Icons.add,
                      size: 16,
                      color: hasShop ? AppTheme.accentGold : Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasShop ? 'Edit' : 'Set',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasShop ? AppTheme.accentGold : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSarafaBanner({
    required BuildContext context,
    required String city,
    required String lastUpdated,
    required double rate24kTola,
    required double rate22kTola,
    required double rate24k10g,
    required double rate22k10g,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryGold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33D4AF37),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.black, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$city Sarafa Rates',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showEditRateDialog(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 13, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          'Edit Rate',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rates Grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildRateTile(
                        label: '24K Per Tola',
                        value: _formatPkr(rate24kTola),
                        highlight: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRateTile(
                        label: '22K Per Tola',
                        value: _formatPkr(rate22kTola),
                        highlight: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildRateTile(
                        label: '10 Grams (24K)',
                        value: _formatPkr(rate24k10g),
                        highlight: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRateTile(
                        label: '10 Grams (22K)',
                        value: _formatPkr(rate22k10g),
                        highlight: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppTheme.textMuted, size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Updated: $lastUpdated',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'All Pakistan Sarafa Market',
                      style: TextStyle(fontSize: 10, color: AppTheme.lightGold, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateTile({
    required String label,
    required String value,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppTheme.primaryGold : AppTheme.borderSubtle,
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: highlight ? AppTheme.primaryGold : AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: highlight ? AppTheme.accentGold : AppTheme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPurityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: AppTheme.primaryGold, size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Market Gold Purity Guide',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Hallmark Standards',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPurityChip('24K', '99.9%', 'Pure Kundan'),
                const SizedBox(width: 6),
                _buildPurityChip('22K', '91.6%', 'Jewelry'),
                const SizedBox(width: 6),
                _buildPurityChip('21K', '87.5%', 'Gulf / Dubai'),
                const SizedBox(width: 6),
                _buildPurityChip('18K', '75.0%', 'Diamond'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurityChip(String karat, String purity, String useCase) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              karat,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              purity,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              useCase,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
