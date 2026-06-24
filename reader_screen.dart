import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/transcription_job.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/rich_arabic_text.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.job});
  final TranscriptionJob job;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double _fontSize   = 17.0;
  String _searchQuery = '';
  bool   _showSearch  = false;
  bool   _exporting   = false;

  final _searchCtrl   = TextEditingController();
  final _scrollCtrl   = ScrollController();

  String get _text => widget.job.refinedTranscription ?? '';

  // ── Export ───────────────────────────────────────────────────────────────

  Future<void> _export(String format) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      if (kIsWeb) {
        // On Web: open URL directly – browser handles the download
        final url = ApiService.instance.exportUrl(widget.job.id, format);
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        final bytes = await ApiService.instance.downloadExport(widget.job.id, format);
        // For mobile: save to temp dir and open
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/transcription.${format}');
        await file.writeAsBytes(bytes);
        await launchUrl(Uri.file(file.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التصدير: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          Expanded(child: _buildTextBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.ink,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.job.audioFilename,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${_text.split(RegExp(r'\s+')).length} كلمة',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        // Search toggle
        IconButton(
          icon: Icon(
            _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            color: _showSearch ? AppColors.teal : AppColors.textMuted,
          ),
          tooltip: 'بحث في النص',
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) {
              _searchQuery = '';
              _searchCtrl.clear();
            }
          }),
        ),
        // Font size control
        IconButton(
          icon: const Icon(Icons.text_fields_rounded, color: AppColors.textMuted),
          tooltip: 'حجم الخط',
          onPressed: () => _showFontSizeSheet(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن مصطلح…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    ).animate().slideY(begin: -0.5, duration: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildTextBody() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: RichArabicText(
              text: _text,
              fontSize: _fontSize,
              searchQuery: _searchQuery,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(top: BorderSide(color: Color(0xFF243447))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ExportButton(
            label: 'PDF',
            icon: Icons.picture_as_pdf_rounded,
            color: AppColors.error,
            onTap: _exporting ? null : () => _export('pdf'),
          ),
          const Gap(12),
          _ExportButton(
            label: 'Word',
            icon: Icons.description_rounded,
            color: AppColors.teal,
            onTap: _exporting ? null : () => _export('docx'),
          ),
          const Gap(12),
          _ExportButton(
            label: 'TXT',
            icon: Icons.text_snippet_rounded,
            color: AppColors.amber,
            onTap: _exporting ? null : () => _export('txt'),
          ),
          if (_exporting) ...[
            const Gap(16),
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Font size bottom sheet ────────────────────────────────────────────────

  void _showFontSizeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('حجم الخط', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Gap(20),
              Row(
                children: [
                  const Icon(Icons.text_fields_rounded, size: 16, color: AppColors.textMuted),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12,
                      max: 28,
                      divisions: 16,
                      activeColor: AppColors.teal,
                      onChanged: (v) {
                        setLocalState(() {});
                        setState(() => _fontSize = v);
                      },
                    ),
                  ),
                  const Icon(Icons.text_fields_rounded, size: 24, color: AppColors.textMuted),
                ],
              ),
              Text(
                '${_fontSize.toStringAsFixed(0)} pt',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const Gap(12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Export button widget ──────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const Gap(8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
