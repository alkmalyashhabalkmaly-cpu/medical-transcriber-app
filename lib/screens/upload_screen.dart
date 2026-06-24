import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/transcription_job.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/file_drop_zone.dart';
import '../widgets/stage_progress_bar.dart';
import 'reader_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // ── File picks ─────────────────────────────────────────────────────────��[...]
  PlatformFile? _audioFile;
  PlatformFile? _pptxFile;

  // ── Upload / pipeline state ───────────────────────────────────────────────
  bool _isProcessing = false;
  double _uploadProgress = 0.0;
  TranscriptionJob? _currentJob;
  String _statusMessage = '';
  String? _errorMessage;

  // ── File pickers ─────────────────────────────────────────────────────────[...]

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'mp4', 'ogg', 'webm', 'flac'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _audioFile = result.files.first);
    }
  }

  Future<void> _pickPptx() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pptx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pptxFile = result.files.first);
    }
  }

  // ── Pipeline ──────────────────────────────────────────────────────────�[...]

  Future<void> _startTranscription() async {
    if (_audioFile == null || _pptxFile == null) return;

    setState(() {
      _isProcessing   = true;
      _uploadProgress = 0;
      _errorMessage   = null;
      _statusMessage  = 'جارٍ رفع الملفات…';
    });

    try {
      // 1. Upload
      final job = await ApiService.instance.createJob(
        audioBytes:    _audioFile!.bytes!,
        audioFilename: _audioFile!.name,
        pptxBytes:     _pptxFile!.bytes!,
        pptxFilename:  _pptxFile!.name,
        onSendProgress: (p) => setState(() => _uploadProgress = p),
      );

      setState(() {
        _currentJob    = job;
        _statusMessage = job.status.labelAr;
      });

      // 2. Stream SSE progress
      await for (final event in ApiService.instance.streamProgress(job.id)) {
        final newStatus = JobStatus.fromString(event['status'] as String? ?? 'pending');
        final pct = event['progress_pct'] as int? ?? 0;
        final msg = event['message'] as String? ?? '';

        setState(() {
          _currentJob   = _currentJob!.copyWith(status: newStatus, progressPct: pct);
          _statusMessage = msg;
        });

        if (newStatus == JobStatus.done) {
          final refined = event['refined_transcription'] as String?;
          final finalJob = refined != null
              ? _currentJob!.copyWith(refinedTranscription: refined)
              : await ApiService.instance.getJob(job.id);

          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReaderScreen(job: finalJob),
            ),
          );
          break;
        }

        if (newStatus == JobStatus.failed) {
          setState(() => _errorMessage = 'فشلت العملية. يرجى المحاولة مجدداً.');
          break;
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'خطأ: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────[...]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const Gap(40),
                  if (!_isProcessing) ...[
                    _buildFileZones(),
                    const Gap(32),
                    _buildSubmitButton(),
                  ] else ...[
                    _buildProgressSection(),
                  ],
                  if (_errorMessage != null) ...[
                    const Gap(24),
                    _buildError(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.teal.withOpacity(0.3)),
              ),
              child: const Icon(Icons.medical_services_rounded, color: AppColors.teal, size: 22),
            ),
            const Gap(14),
            Text(
              'المُفرِّغ الطبي',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
        const Gap(10),
        Text(
          'تفريغ المحاضرات الطبية من العربية اليمنية إلى نص أكاديمي فصيح',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Widget _buildFileZones() {
    return Column(
      children: [
        FileDropZone(
          icon: Icons.headphones_rounded,
          label: 'ملف الصوت',
          hint: 'MP3 · WAV · M4A · FLAC',
          acceptedFile: _audioFile,
          accentColor: AppColors.teal,
          onTap: _pickAudio,
        ),
        const Gap(16),
        FileDropZone(
          icon: Icons.slideshow_rounded,
          label: 'ملف العرض التقديمي',
          hint: 'PPTX فقط',
          acceptedFile: _pptxFile,
          accentColor: AppColors.amber,
          onTap: _pickPptx,
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildSubmitButton() {
    final canSubmit = _audioFile != null && _pptxFile != null;
    return ElevatedButton.icon(
      onPressed: canSubmit ? _startTranscription : null,
      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
      label: const Text('بدء التفريغ والتحرير'),
      style: ElevatedButton.styleFrom(
        backgroundColor: canSubmit ? AppColors.teal : AppColors.ink,
        foregroundColor: canSubmit ? Colors.white : AppColors.textMuted,
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildProgressSection() {
    final job = _currentJob;
    return Column(
      children: [
        // Upload progress bar
        if (_uploadProgress < 1.0) ...[
          _ProgressCard(
            icon: Icons.cloud_upload_rounded,
            title: 'رفع الملفات',
            subtitle: '${(_uploadProgress * 100).toStringAsFixed(0)}%',
            color: AppColors.teal,
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.ink,
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
          ),
        ] else if (job != null) ...[
          StageProgressBar(job: job),
          const Gap(24),
          _ProgressCard(
            icon: Icons.more_horiz_rounded,
            title: _statusMessage,
            subtitle: '${job.progressPct}% مكتمل',
            color: AppColors.tealLight,
            child: LinearPercentIndicator(
              percent: job.progressPct / 100,
              lineHeight: 10,
              backgroundColor: AppColors.ink,
              progressColor: AppColors.teal,
              barRadius: const Radius.circular(8),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        const Gap(16),
        const _PulsingDot(),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const Gap(12),
          Expanded(
            child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => setState(() {
              _errorMessage  = null;
              _isProcessing  = false;
            }),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────��[...]

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Gap(10),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                ),
                Text(subtitle,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const Gap(16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: const Text(
        '● ● ●',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.teal, letterSpacing: 8, fontSize: 12),
      ),
    );
  }
}
