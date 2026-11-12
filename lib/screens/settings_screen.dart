import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final PreferencesService prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateController;
  late TextEditingController _taxController;
  late TextEditingController _makingController;

  final List<String> _currencies = ['Rs.', 'PKR', 'AED', 'SAR', '₹', '\$', '€', '£'];
  final List<String> _units = ['g', 'tola', 'masha', 'ratti', 'oz'];

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: widget.prefs.sarafaRate24kTola.toStringAsFixed(0));
    _taxController = TextEditingController(text: widget.prefs.defaultTax.toStringAsFixed(1));
    _makingController = TextEditingController(text: widget.prefs.defaultMaking.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _rateController.dispose();
    _taxController.dispose();
    _makingController.dispose();
    super.dispose();
  }

  Future<void> _launchExternalUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.prefs,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.navyBg,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppTheme.primaryGold),
                SizedBox(width: 8),
                Text('Settings & Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader('General Preferences'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preferred Currency
                      const Text(
                        'Currency Symbol',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _currencies.map((curr) {
                          final isSel = widget.prefs.currency == curr;
                          return ChoiceChip(
                            label: Text(curr),
                            selected: isSel,
                            selectedColor: AppTheme.primaryGold,
                            backgroundColor: AppTheme.inputBg,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.black : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) widget.prefs.setCurrency(curr);
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(color: AppTheme.borderSubtle, height: 28),

                      // Default Weight Unit
                      const Text(
                        'Default Weight Unit',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _units.map((unit) {
                          final isSel = widget.prefs.defaultUnit == unit;
                          return ChoiceChip(
                            label: Text(unit.toUpperCase()),
                            selected: isSel,
                            selectedColor: AppTheme.primaryGold,
                            backgroundColor: AppTheme.inputBg,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.black : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) widget.prefs.setDefaultUnit(unit);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Sarafa Rates & Making Defaults'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: '24K Gold Rate Per Tola',
                          prefixText: '${widget.prefs.currency} ',
                          suffixText: 'PKR',
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            widget.prefs.updateSarafaRates(rate24kTola: parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _makingController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Default Making Charges (Mazdoori)',
                          prefixText: '${widget.prefs.currency} ',
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 0) {
                            widget.prefs.setDefaultMaking(parsed);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Market Resources & Standards'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.public, color: AppTheme.primaryGold),
                      title: const Text('Live International Gold Rates'),
                      subtitle: const Text('goldprice.org'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchExternalUrl('https://goldprice.org'),
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_outlined, color: AppTheme.primaryGold),
                      title: const Text('Pakistan Sarafa Standards Guide'),
                      subtitle: const Text('Karachi & Lahore Sarafa Association Metrics'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchExternalUrl('https://en.wikipedia.org/wiki/Tola_(unit)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('About Pak Gold Pro'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.monetization_on, color: AppTheme.primaryGold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pak Gold Pro',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                              ),
                              Text(
                                'Digital Sarafa Toolkit & Bahi-Khata',
                                style: TextStyle(color: AppTheme.accentGold, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Engineered for Pakistani jewelers, goldsmiths, and gold buyers. Accurate tola-masha-ratti calculations, live Karachi/Lahore sarafa rates, scrap katan deductions, and 1-tap WhatsApp invoice parchas.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Version 1.0.0 Pro',
                        style: TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
