import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/calculation_record.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../utils/gold_math.dart';

class HistoryScreen extends StatefulWidget {
  final PreferencesService prefs;

  const HistoryScreen({super.key, required this.prefs});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all'; // 'all', 'jewelry', 'scrap'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  }

  String _formatPkr(double amount) {
    final formatter = NumberFormat('#,##,###');
    return 'Rs. ${formatter.format(amount.round())}';
  }

  String _buildRecordReceiptText(CalculationRecord record) {
    final now = _formatDate(record.timestamp);
    final tmr = GoldMath.gramsToTMR(record.weight);
    final isScrap = record.type == 'scrap';

    final shopTitle = widget.prefs.shopName.trim().isNotEmpty
        ? widget.prefs.shopName.trim().toUpperCase()
        : (isScrap ? 'PAK GOLD PRO — OLD GOLD / SCRAP PARCH' : 'PAK GOLD PRO — SARAFA BILL / PARCH');
    final shopSubtitle = widget.prefs.shopContact.trim().isNotEmpty
        ? '\n📞 *Rabta:* ${widget.prefs.shopContact.trim()}'
        : '';

    if (isScrap) {
      return '''
🌟 *$shopTitle* 🌟$shopSubtitle
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 *Tareekh:* $now
👤 *Reference:* ${record.title}
👑 *Karat:* ${record.karat}K (${GoldMath.getHallmarkLabel(record.karat)})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ *Kul Wazan (Gross):* ${record.grossWeight > 0 ? record.grossWeight.toStringAsFixed(3) : record.weight.toStringAsFixed(3)} g
💎 *Nageena (Stone):* ${record.stoneWeight.toStringAsFixed(3)} g
✨ *Safi Wazan (Net):* ${record.weight.toStringAsFixed(3)} g
🏷️ *Tola/Masha/Ratti:* ${tmr.formatted}
🪙 *Pure Gold Equivalent:* ${record.pureGoldWeight.toStringAsFixed(3)} g
🔥 *Katan / Katoti Loss:* ${record.lossPercent.toStringAsFixed(1)}%
════════════════════════════
💵 *KUL CASH PAYOUT:* ${_formatPkr(record.totalAmount)}
════════════════════════════
✨ *Pak Gold Pro — Digital Sarafa Bahi-Khata*''';
    } else {
      return '''
🌟 *$shopTitle* 🌟$shopSubtitle
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 *Tareekh:* $now
💍 *Item:* ${record.title}
👑 *Karat:* ${record.karat}K (${GoldMath.getHallmarkLabel(record.karat)})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚖️ *Kul Wazan (Gross):* ${record.grossWeight > 0 ? record.grossWeight.toStringAsFixed(3) : record.weight.toStringAsFixed(3)} g
💎 *Nageena (Stone):* ${record.stoneWeight.toStringAsFixed(3)} g
✨ *Safi Wazan (Net):* ${record.weight.toStringAsFixed(3)} g
🏷️ *Tola/Masha/Ratti:* ${tmr.formatted}
🪙 *Khalis Sona (Pure):* ${record.pureGoldWeight.toStringAsFixed(3)} g
📈 *Rate/g:* ${_formatPkr(record.ratePerGram)}
🔨 *Mazdoori:* ${_formatPkr(record.makingCharges)}
🏷️ *Discount:* ${_formatPkr(record.discount)}
════════════════════════════
🏆 *KUL PAYABLE RAQAM:* ${_formatPkr(record.totalAmount)}
════════════════════════════
✨ *Pak Gold Pro — Digital Sarafa Bahi-Khata*''';
    }
  }

  Future<void> _shareToWhatsApp(CalculationRecord record) async {
    final text = _buildRecordReceiptText(record);
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
              content: Text('WhatsApp not detected. Receipt copied to Clipboard!'),
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
            content: Text('Receipt copied to Clipboard!'),
            backgroundColor: AppTheme.primaryGold,
          ),
        );
      }
    }
  }

  void _copyToClipboard(CalculationRecord record) {
    Clipboard.setData(ClipboardData(text: _buildRecordReceiptText(record)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parch copied to Clipboard!'),
        backgroundColor: AppTheme.primaryGold,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRecordDetails(CalculationRecord record) {
    final tmr = GoldMath.gramsToTMR(record.weight);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.primaryGold, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        record.type == 'scrap' ? Icons.recycling : Icons.verified,
                        color: AppTheme.primaryGold,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record.type == 'scrap' ? 'Scrap Parch Detail' : 'Jewelry Parch Detail',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 8),
              _buildDetailItem('Item / Title:', record.title),
              _buildDetailItem('Date & Time:', _formatDate(record.timestamp)),
              _buildDetailItem('Karat & Purity:', '${record.karat}K (${GoldMath.getHallmarkLabel(record.karat)})'),
              if (record.grossWeight > 0)
                _buildDetailItem('Kul Wazan (Gross):', '${record.grossWeight.toStringAsFixed(3)} g'),
              if (record.stoneWeight > 0)
                _buildDetailItem('Nageena (Stone):', '${record.stoneWeight.toStringAsFixed(3)} g'),
              _buildDetailItem('Safi Wazan (Net):', '${record.weight.toStringAsFixed(3)} g'),
              _buildDetailItem('Tola / Masha / Ratti:', tmr.formatted),
              _buildDetailItem('Pure Gold (24K eq):', '${record.pureGoldWeight.toStringAsFixed(3)} g'),
              if (record.makingCharges > 0)
                _buildDetailItem('Mazdoori (Making):', _formatPkr(record.makingCharges)),
              if (record.discount > 0)
                _buildDetailItem('Discount:', '- ${_formatPkr(record.discount)}'),
              const Divider(color: AppTheme.borderSubtle, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    record.type == 'scrap' ? 'Total Payout:' : 'Total Payable:',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                  ),
                  Text(
                    _formatPkr(record.totalAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accentGold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _shareToWhatsApp(record);
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _copyToClipboard(record);
                      },
                      icon: const Icon(Icons.copy, color: AppTheme.primaryGold, size: 18),
                      label: const Text('Copy Text', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryGold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear All History?', style: TextStyle(color: AppTheme.textPrimary)),
          content: const Text(
            'This will permanently delete all saved Sarafa parchas and scrap records.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.prefs.clearHistory();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
              child: const Text('Clear All', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.prefs,
      builder: (context, _) {
        var records = widget.prefs.history;

        // Apply type filter
        if (_selectedFilter != 'all') {
          records = records.where((r) => r.type == _selectedFilter).toList();
        }

        // Apply search query
        final query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          records = records.where((r) {
            return r.title.toLowerCase().contains(query) ||
                r.karat.toString().contains(query) ||
                r.totalAmount.toString().contains(query);
          }).toList();
        }

        return Scaffold(
          backgroundColor: AppTheme.navyBg,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.history_edu_rounded, color: AppTheme.primaryGold),
                SizedBox(width: 8),
                Text(
                  'Saved Parch / History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              if (widget.prefs.history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.alertRed),
                  tooltip: 'Clear All History',
                  onPressed: _confirmClearAll,
                ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search parchas (item name, karat, etc.)...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterChip('all', 'All Parchas (${widget.prefs.history.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('jewelry', 'Jewelry'),
                        const SizedBox(width: 8),
                        _buildFilterChip('scrap', 'Scrap Melter'),
                      ],
                    ),
                  ],
                ),
              ),

              // History List or Empty state
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: AppTheme.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No saved parchas found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Save calculations from Jewelry or Scrap screens',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _buildRecordCard(record);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentGold : AppTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(CalculationRecord record) {
    final isScrap = record.type == 'scrap';

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.alertRed,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        widget.prefs.deleteHistoryRecord(record.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${record.title} deleted'),
            backgroundColor: AppTheme.cardBg,
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppTheme.primaryGold,
              onPressed: () {
                widget.prefs.addHistoryRecord(record);
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _showRecordDetails(record),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isScrap ? AppTheme.alertRed.withValues(alpha: 0.15) : AppTheme.primaryGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isScrap ? Icons.recycling : Icons.verified,
                              color: isScrap ? AppTheme.alertRed : AppTheme.primaryGold,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              record.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Text(
                        '${record.karat}K',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(record.timestamp),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    Text(
                      'Net: ${record.weight.toStringAsFixed(3)} g',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.borderSubtle, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isScrap ? 'Cash Payout:' : 'Payable Raqam:',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        Text(
                          _formatPkr(record.totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accentGold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 20),
                          tooltip: 'Share to WhatsApp',
                          onPressed: () => _shareToWhatsApp(record),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppTheme.primaryGold, size: 20),
                          tooltip: 'Copy Text',
                          onPressed: () => _copyToClipboard(record),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => widget.prefs.deleteHistoryRecord(record.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
